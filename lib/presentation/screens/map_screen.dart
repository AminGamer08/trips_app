import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../services/location_service.dart';
import '../../utilities/app_exception.dart';
import '../map/map_provider.dart';
import '../widgets/common.dart';
import '../widgets/place_card.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  PlaceCategory? _category;
  String? _selected;
  Coordinates? _location;
  bool _locating = false, _picking = false;
  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .currentPosition();
      if (mounted) {
        setState(() => _location = position);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) {
      final places = data.places
          .where((p) => _category == null || p.category == _category)
          .toList();
      final selected = places.where((p) => p.id == _selected).firstOrNull;
      return Stack(
        children: [
          Positioned.fill(
            child: JournalMap(
              request: MapRequest(
                places: places,
                selectedId: _selected,
                center: _location,
                currentLocation: _location,
                onPlaceTap: (place) => setState(() => _selected = place.id),
                onCoordinateTap: !_picking
                    ? null
                    : (position) {
                        setState(() => _picking = false);
                        context.push(
                          '/place/new?lat=${position.latitude}&lng=${position.longitude}',
                        );
                      },
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchBar(
                    hintText: 'Deine Welt durchsuchen',
                    leading: const Icon(Icons.search_rounded),
                    readOnly: true,
                    onTap: () => context.push('/search'),
                    trailing: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          '${places.length} Orte',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Alle Orte'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                        ),
                        for (final category in PlaceCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(category.icon, size: 16),
                              label: Text(category.label),
                              selected: _category == category,
                              onSelected: (selected) => setState(
                                () => _category = selected ? category : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_picking)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.touch_app_outlined),
                        title: const Text('Tippe auf deinen Erinnerungsort'),
                        subtitle: const Text(
                          'Zoome für eine genauere Auswahl hinein.',
                        ),
                        trailing: IconButton(
                          tooltip: 'Abbrechen',
                          onPressed: () => setState(() => _picking = false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: selected == null ? 42 : 173,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FloatingActionButton.small(
                  heroTag: 'location',
                  tooltip: 'Zu meinem aktuellen Standort',
                  onPressed: _locating ? null : _locate,
                  child: _locating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'map-add',
                  onPressed: () => setState(() => _picking = !_picking),
                  icon: Icon(
                    _picking
                        ? Icons.close_rounded
                        : Icons.add_location_alt_outlined,
                  ),
                  label: Text(_picking ? 'Abbrechen' : 'Ort festhalten'),
                ),
              ],
            ),
          ),
          if (selected != null)
            Positioned(
              left: 18,
              right: 18,
              bottom: 34,
              child: Enter(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: PlaceTile(selected),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          tooltip: 'Vorschau schließen',
                          onPressed: () => setState(() => _selected = null),
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

Future<Coordinates?> pickMapPoint(
  BuildContext context, {
  Coordinates? initial,
}) => showModalBottomSheet<Coordinates>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _MapPicker(initial: initial),
);

class _MapPicker extends StatefulWidget {
  const _MapPicker({this.initial});
  final Coordinates? initial;
  @override
  State<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<_MapPicker> {
  late Coordinates? _selected = widget.initial;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .83,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              Text(
                'Wo war dein Moment?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Verschiebe die Karte und tippe auf einen Punkt.'),
            ],
          ),
        ),
        Expanded(
          child: JournalMap(
            request: MapRequest(
              places: const [],
              center: widget.initial,
              initialZoom: widget.initial == null ? 4 : 12,
              currentLocation: _selected,
              onCoordinateTap: (point) => setState(() => _selected = point),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: Space.page,
            child: Column(
              children: [
                Text(
                  _selected == null
                      ? 'Noch kein Punkt ausgewählt'
                      : '${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected),
                    child: const Text('Diesen Standort übernehmen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
