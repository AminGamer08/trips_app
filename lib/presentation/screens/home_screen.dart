import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/journal_stats.dart';
import '../../utilities/formatters.dart';
import '../map/map_provider.dart';
import '../widgets/common.dart';
import '../widgets/place_card.dart';
import '../widgets/trip_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) {
      final stats = JournalStats(data.places, data.trips);
      final today = DateUtils.dateOnly(DateTime.now());
      final lastTrip =
          data.trips.where((t) => !t.startDate.isAfter(today)).firstOrNull ??
          data.trips.lastOrNull;
      final scheme = Theme.of(context).colorScheme;
      return JournalPage(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: scheme.onPrimary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'adventure journal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(letterSpacing: -.5),
                ),
              ),
              IconButton(
                tooltip: 'Erinnerungen suchen',
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: 30),
          PageHeading(
            eyebrow: 'Schön, dass du da bist',
            title: 'Deine Welt.\nDeine Geschichten.',
            subtitle: 'Kleine Momente. Unvergessliche Abenteuer.',
            trailing: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Icon(
                Icons.wb_sunny_outlined,
                color: scheme.tertiary,
                size: 28,
              ),
            ),
          ),
          if (lastTrip != null)
            Enter(
              child: TripCard(
                lastTrip,
                placeCount: data.placesForTrip(lastTrip.id).length,
                featured: true,
              ),
            )
          else
            Card(
              child: EmptyState(
                icon: Icons.flight_takeoff_rounded,
                title: 'Die Welt wartet auf dich',
                message:
                    'Dein nächstes Abenteuer beginnt mit einer neuen Reise.',
                action: 'Reise anlegen',
                onAction: () => context.push('/trip/new'),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Metric(
                  icon: Icons.location_on_outlined,
                  value: '${data.places.length}',
                  label: 'Orte entdeckt',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Metric(
                  icon: Icons.public_rounded,
                  value: '${stats.countries}',
                  label: 'Länder besucht',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Metric(
                  icon: Icons.airplane_ticket_outlined,
                  value: '${data.trips.length}',
                  label: 'Reisen erlebt',
                ),
              ),
            ],
          ),
          SectionHeading(
            'Frisch im Journal',
            action: 'Alle ansehen',
            onAction: () => context.push('/search'),
          ),
          if (data.places.isEmpty)
            Card(
              child: EmptyState(
                icon: Icons.add_location_alt_outlined,
                title: 'Ein Ort. Eine Geschichte.',
                message: 'Speichere deinen ersten Lieblingsplatz.',
                action: 'Ort hinzufügen',
                onAction: () => context.push('/place/new'),
              ),
            )
          else
            SizedBox(
              height: 268,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.places.take(8).length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    SizedBox(width: 250, child: PlaceCard(data.places[index])),
              ),
            ),
          SectionHeading(
            'Deine Spuren auf der Welt',
            action: 'Karte öffnen',
            onAction: () => context.go('/map'),
          ),
          Card(
            child: Column(
              children: [
                SizedBox(
                  height: 205,
                  child: JournalMap(
                    request: MapRequest(
                      places: data.places,
                      interactive: false,
                      onPlaceTap: (place) => context.push('/place/${place.id}'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.explore_outlined, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${stats.cities} Städte. So viele Erinnerungen.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zur Karte',
                        onPressed: () => context.go('/map'),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: .5),
              borderRadius: Space.radius,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: scheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    data.places.isEmpty
                        ? 'Deine schönsten Erinnerungen verdienen einen Platz.'
                        : '${stats.photos} festgehaltene Momente und ${decimalLabel(stats.averageRating)} Sterne voller Erinnerungen.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('home-add-place'),
              onPressed: () => context.push('/place/new'),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Einen neuen Ort festhalten'),
            ),
          ),
        ],
      );
    },
  );
}
