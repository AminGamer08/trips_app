import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import 'map_provider.dart';

class Mercator {
  static Offset project(Coordinates p) {
    final lat = p.latitude.clamp(-85.0511, 85.0511) * math.pi / 180;
    return Offset(
      (p.longitude + 180) / 360,
      (1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2,
    );
  }

  static Coordinates unproject(Offset p) => Coordinates(
    math.atan(
          (math.exp(math.pi * (1 - 2 * p.dy)) -
                  math.exp(-math.pi * (1 - 2 * p.dy))) /
              2,
        ) *
        180 /
        math.pi,
    ((p.dx * 360) % 360) - 180,
  );
}

final worldGeometryProvider = FutureProvider<List<List<Offset>>>((ref) async {
  final json =
      jsonDecode(await rootBundle.loadString('assets/maps/world.geojson'))
          as Map;
  final rings = <List<Offset>>[];
  for (final feature in json['features'] as List) {
    final geometry = feature['geometry'] as Map;
    final coordinates = geometry['coordinates'] as List;
    final polygons = geometry['type'] == 'Polygon'
        ? [coordinates]
        : coordinates;
    for (final polygon in polygons) {
      for (final ring in polygon as List) {
        rings.add(
          (ring as List)
              .map(
                (p) => Mercator.project(
                  Coordinates(
                    (p[1] as num).toDouble(),
                    (p[0] as num).toDouble(),
                  ),
                ),
              )
              .toList(),
        );
      }
    }
  }
  return rings;
});

class OfflineMap extends ConsumerStatefulWidget {
  const OfflineMap({super.key, required this.request});
  final MapRequest request;
  @override
  ConsumerState<OfflineMap> createState() => _OfflineMapState();
}

class _OfflineMapState extends ConsumerState<OfflineMap> {
  Offset _center = Mercator.project(const Coordinates(48.8, 7));
  double _zoom = 4, _gestureZoom = 4;
  Offset _gestureCenter = Offset.zero, _gestureFocal = Offset.zero;
  Size? _lastSize;
  double get _worldSize => 256 * math.pow(2, _zoom).toDouble();
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OfflineMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.center != oldWidget.request.center &&
        widget.request.center != null) {
      _center = Mercator.project(widget.request.center!);
      _zoom = widget.request.initialZoom ?? 13;
    }
  }

  void _fit(Size size) {
    if (widget.request.center != null) {
      _center = Mercator.project(widget.request.center!);
      _zoom = widget.request.initialZoom ?? 13;
      return;
    }
    if (widget.request.places.isEmpty) {
      return;
    }
    final points = widget.request.places
        .map((p) => Mercator.project(p.coordinates))
        .toList();
    final minX = points.map((p) => p.dx).reduce(math.min),
        maxX = points.map((p) => p.dx).reduce(math.max);
    final minY = points.map((p) => p.dy).reduce(math.min),
        maxY = points.map((p) => p.dy).reduce(math.max);
    _center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final xZoom =
        math.log(
          math.max(60, size.width - 110) /
              (256 * math.max(maxX - minX, .00012)),
        ) /
        math.ln2;
    final yZoom =
        math.log(
          math.max(60, size.height - 110) /
              (256 * math.max(maxY - minY, .00012)),
        ) /
        math.ln2;
    _zoom =
        widget.request.initialZoom ??
        math.min(xZoom, yZoom).clamp(1, 15).toDouble();
  }

  Offset _screen(Coordinates p, Size size) {
    final projected = Mercator.project(p);
    var dx = projected.dx - _center.dx;
    if (dx > .5) {
      dx -= 1;
    } else if (dx < -.5) {
      dx += 1;
    }
    return Offset(dx, projected.dy - _center.dy) * _worldSize +
        Offset(size.width / 2, size.height / 2);
  }

  List<_Cluster> _clusters(Size size) {
    final result = <_Cluster>[];
    for (final place in widget.request.places) {
      final point = _screen(place.coordinates, size);
      final existing = result
          .where((c) => (c.point - point).distance < 40)
          .firstOrNull;
      if (existing == null) {
        result.add(_Cluster(point, [place]));
      } else {
        existing.places.add(place);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (_lastSize == null) {
        _fit(size);
      }
      _lastSize = size;
      final scheme = Theme.of(context).colorScheme;
      final geometry = ref.watch(worldGeometryProvider);
      final clusters = _clusters(size);
      final location = widget.request.currentLocation;
      return ClipRect(
        child: GestureDetector(
          onScaleStart: !widget.request.interactive
              ? null
              : (d) {
                  _gestureZoom = _zoom;
                  _gestureCenter = _center;
                  _gestureFocal = d.localFocalPoint;
                },
          onScaleUpdate: !widget.request.interactive
              ? null
              : (d) => setState(() {
                  _zoom = (_gestureZoom + math.log(d.scale) / math.ln2).clamp(
                    1,
                    18,
                  );
                  final midpoint = Offset(size.width / 2, size.height / 2);
                  final anchor =
                      _gestureCenter +
                      (_gestureFocal - midpoint) /
                          (256 * math.pow(2, _gestureZoom).toDouble());
                  _center =
                      anchor - (d.localFocalPoint - midpoint) / _worldSize;
                  _center = Offset(_center.dx % 1, _center.dy.clamp(0, 1));
                }),
          onTapUp: widget.request.onCoordinateTap == null
              ? null
              : (d) {
                  final point =
                      _center +
                      (d.localPosition -
                              Offset(size.width / 2, size.height / 2)) /
                          _worldSize;
                  widget.request.onCoordinateTap!(
                    Mercator.unproject(Offset(point.dx, point.dy.clamp(0, 1))),
                  );
                },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WorldPainter(
                    rings: geometry.asData?.value ?? [],
                    center: _center,
                    worldSize: _worldSize,
                    scheme: scheme,
                    points: widget.request.connectPlaces
                        ? widget.request.places
                              .map((p) => _screen(p.coordinates, size))
                              .toList()
                        : [],
                  ),
                ),
              ),
              for (final cluster in clusters)
                if (cluster.point.dx > -30 &&
                    cluster.point.dx < size.width + 30 &&
                    cluster.point.dy > -30 &&
                    cluster.point.dy < size.height + 30)
                  Positioned(
                    left: cluster.point.dx - 23,
                    top: cluster.point.dy - 38,
                    child: Semantics(
                      button: true,
                      label: cluster.places.length > 1
                          ? '${cluster.places.length} Orte in ${cluster.places.first.city}'
                          : cluster.places.first.name,
                      child: Tooltip(
                        message: cluster.places.length > 1
                            ? '${cluster.places.length} Orte · zum Vergrößern tippen'
                            : cluster.places.first.name,
                        child: Material(
                          color: scheme.surfaceContainerLowest,
                          elevation: 3,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              if (cluster.places.length > 1 && _zoom < 18) {
                                setState(() {
                                  _center = Mercator.project(
                                    cluster.places.first.coordinates,
                                  );
                                  _zoom = (_zoom + 2).clamp(1, 18);
                                });
                              } else if (cluster.places.length > 1) {
                                showModalBottomSheet<void>(
                                  context: context,
                                  builder: (context) => SafeArea(
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: [
                                        for (final p in cluster.places)
                                          ListTile(
                                            title: Text(p.name),
                                            leading: Icon(p.category.icon),
                                            onTap: () {
                                              Navigator.pop(context);
                                              widget.request.onPlaceTap?.call(
                                                p,
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                widget.request.onPlaceTap?.call(
                                  cluster.places.first,
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: Space.duration,
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color:
                                    cluster.places.any(
                                      (p) => p.id == widget.request.selectedId,
                                    )
                                    ? scheme.primary
                                    : scheme.surfaceContainerLowest,
                              ),
                              child: Center(
                                child: cluster.places.length > 1
                                    ? Text(
                                        '${cluster.places.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: scheme.primary),
                                      )
                                    : Icon(
                                        cluster.places.first.category.icon,
                                        size: 22,
                                        color:
                                            cluster.places.first.id ==
                                                widget.request.selectedId
                                            ? scheme.onPrimary
                                            : cluster.places.first.category
                                                  .color(context),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              if (location != null)
                Positioned(
                  left: _screen(location, size).dx - 9,
                  top: _screen(location, size).dy - 9,
                  child: Semantics(
                    label: 'Dein aktueller Standort',
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.surfaceContainerLowest,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: .2),
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (geometry.hasError)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Kartendaten nicht verfügbar. Deine Pins bleiben sichtbar.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              if (widget.request.interactive)
                Positioned(
                  right: 14,
                  bottom: 42,
                  child: Column(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Vergrößern',
                        onPressed: () =>
                            setState(() => _zoom = (_zoom + 1).clamp(1, 18)),
                        icon: const Icon(Icons.add_rounded),
                      ),
                      const SizedBox(height: 6),
                      IconButton.filledTonal(
                        tooltip: 'Verkleinern',
                        onPressed: () =>
                            setState(() => _zoom = (_zoom - 1).clamp(1, 18)),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(height: 6),
                      IconButton.filledTonal(
                        tooltip: 'Alle Orte zeigen',
                        onPressed: () => setState(() => _fit(size)),
                        icon: const Icon(Icons.fit_screen_rounded),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 9,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'Übersichtskarte · offline · Natural Earth',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Cluster {
  _Cluster(this.point, this.places);
  final Offset point;
  final List<Place> places;
}

class _WorldPainter extends CustomPainter {
  _WorldPainter({
    required this.rings,
    required this.center,
    required this.worldSize,
    required this.scheme,
    required this.points,
  });
  final List<List<Offset>> rings;
  final Offset center;
  final double worldSize;
  final ColorScheme scheme;
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = scheme.secondaryContainer.withValues(alpha: .48),
    );
    final origin = Offset(size.width / 2, size.height / 2);
    final gridPaint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: .2)
      ..strokeWidth = .7;
    final grid =
        worldSize / math.pow(2, (math.log(worldSize / 90) / math.ln2).floor());
    for (
      double x = (origin.dx - center.dx * worldSize) % grid;
      x < size.width;
      x += grid
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (
      double y = (origin.dy - center.dy * worldSize) % grid;
      y < size.height;
      y += grid
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (final ring in rings) {
      if (ring.isEmpty) {
        continue;
      }
      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final point = (ring[i] - center) * worldSize + origin;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      if (!path.getBounds().overlaps(Offset.zero & size)) {
        continue;
      }
      canvas.drawPath(
        path,
        Paint()..color = scheme.surfaceContainerLowest.withValues(alpha: .85),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = scheme.outlineVariant.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = scheme.primary.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) =>
      old.center != center ||
      old.worldSize != worldSize ||
      old.scheme != scheme ||
      old.rings != rings ||
      old.points != points;
}
