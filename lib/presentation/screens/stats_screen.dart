import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../models/journal_stats.dart';
import '../../utilities/formatters.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) {
      final stats = JournalStats(data.places, data.trips),
          scheme = Theme.of(context).colorScheme;
      final categories = stats.categories.entries
          .where((e) => e.value > 0)
          .toList();
      return JournalPage(
        children: [
          const PageHeading(
            eyebrow: 'Dein Abenteuer in Zahlen',
            title: 'So viel erlebt.',
            subtitle: 'Jeder Ort ist ein Stück deiner Geschichte.',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 650 ? 3 : 2;
              final metrics = [
                Metric(
                  icon: Icons.public_rounded,
                  value: '${stats.countries}',
                  label: 'Länder besucht',
                ),
                Metric(
                  icon: Icons.location_city_outlined,
                  value: '${stats.cities}',
                  label: 'Städte entdeckt',
                ),
                Metric(
                  icon: Icons.flight_takeoff_rounded,
                  value: '${data.trips.length}',
                  label: 'Reisen erlebt',
                ),
                Metric(
                  icon: Icons.location_on_outlined,
                  value: '${data.places.length}',
                  label: 'Orte gesammelt',
                ),
                Metric(
                  icon: Icons.star_outline_rounded,
                  value: data.places.isEmpty
                      ? '–'
                      : decimalLabel(stats.averageRating),
                  label: 'Ø Bewertung',
                ),
                Metric(
                  icon: Icons.photo_library_outlined,
                  value: '${stats.photos}',
                  label: 'Fotos festgehalten',
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 12) / columns,
                      child: metric,
                    ),
                ],
              );
            },
          ),
          const SectionHeading('Was dich nach draußen zieht'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  SizedBox(
                    height: 190,
                    width: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 850),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CustomPaint(
                            size: const Size(190, 190),
                            painter: _DonutPainter(
                              values: categories.map((e) => e.value).toList(),
                              colors: categories
                                  .map((e) => e.key.color(context))
                                  .toList(),
                              track: scheme.surfaceContainerHigh,
                              progress: value,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${data.places.length}',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            Text(
                              'Lieblingsplätze',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (categories.isEmpty)
                    const Text('Deine Kategorien wachsen mit jedem neuen Ort.')
                  else
                    for (final entry in categories)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: entry.key
                                    .color(context)
                                    .withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                entry.key.icon,
                                size: 18,
                                color: entry.key.color(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${(entry.value / data.places.length * 100).round()} %',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SectionHeading('Ein Jahr voller Geschichten'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reisen pro Jahr',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (stats.tripsByYear.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text('Deine erste Reise macht den Anfang.'),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final entry in stats.tripsByYear.entries)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${entry.value}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0,
                                        end:
                                            entry.value /
                                            stats.tripsByYear.values.reduce(
                                              math.max,
                                            ),
                                      ),
                                      duration:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? Duration.zero
                                          : const Duration(milliseconds: 750),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, _) => Container(
                                        height: 110 * value,
                                        width: 58,
                                        decoration: BoxDecoration(
                                          color: scheme.primaryContainer,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(14),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${entry.key}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeading('Hier zieht es dich hin'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  if (stats.topCountries.isEmpty)
                    const Text('Deine Lieblingsländer warten noch auf dich.')
                  else
                    for (final entry in stats.topCountries.entries.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  '${entry.value} Orte',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end:
                                    entry.value /
                                    stats.topCountries.values.first,
                              ),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 800),
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 9,
                                    borderRadius: BorderRadius.circular(8),
                                    color: scheme.primary,
                                    backgroundColor:
                                        scheme.surfaceContainerHigh,
                                  ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: Space.radius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.route_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  '${decimalLabel(stats.distanceKm * (data.settings.unit == DistanceUnit.miles ? .621371 : 1))} ${data.settings.unit == DistanceUnit.miles ? 'mi' : 'km'}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Luftlinie zwischen deinen Orten je Reise',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
    required this.progress,
  });
  final List<int> values;
  final List<Color> colors;
  final Color track;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(14),
        paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    final total = values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return;
    }
    double angle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      canvas.drawArc(
        rect,
        angle,
        math.max(0, sweep * progress - .11),
        false,
        paint..color = colors[i],
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.colors != colors ||
      old.track != track;
}
