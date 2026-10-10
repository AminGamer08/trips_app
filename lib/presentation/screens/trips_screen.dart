import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../utilities/formatters.dart';
import '../widgets/common.dart';
import '../widgets/journal_photo.dart';
import '../widgets/trip_card.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _grid = true;
  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) => JournalPage(
      children: [
        PageHeading(
          eyebrow: 'Deine Reisesammlung',
          title: 'Raus in die Welt.',
          subtitle: '${data.trips.length} Reisen, die bleiben.',
          trailing: IconButton.filledTonal(
            tooltip: 'Neue Reise',
            onPressed: () => context.push('/trip/new'),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        Row(
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.grid_view_rounded),
                  label: Text('Karten'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.view_agenda_outlined),
                  label: Text('Liste'),
                ),
              ],
              selected: {_grid},
              onSelectionChanged: (selection) =>
                  setState(() => _grid = selection.first),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (data.trips.isEmpty)
          EmptyState(
            icon: Icons.luggage_outlined,
            title: 'Bereit für dein nächstes Kapitel?',
            message:
                'Sammle Orte, Fotos und kleine Geschichten in einer Reise.',
            action: 'Erste Reise anlegen',
            onAction: () => context.push('/trip/new'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (!_grid) {
                return Column(
                  children: [
                    for (final trip in data.trips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: ClipRRect(
                              borderRadius: Space.smallRadius,
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: JournalPhoto(trip.coverId),
                              ),
                            ),
                            title: Text(
                              trip.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              '${dateRange(trip.startDate, trip.endDate)}\n${data.placesForTrip(trip.id).length} Orte',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push('/trip/${trip.id}'),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final trip in data.trips)
                    SizedBox(
                      width: constraints.maxWidth > 650
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth,
                      child: Enter(
                        child: TripCard(
                          trip,
                          placeCount: data.placesForTrip(trip.id).length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    ),
  );
}
