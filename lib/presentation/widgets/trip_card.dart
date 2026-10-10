import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../utilities/formatters.dart';
import 'journal_photo.dart';

class TripCard extends StatelessWidget {
  const TripCard(
    this.trip, {
    super.key,
    required this.placeCount,
    this.featured = false,
  });
  final Trip trip;
  final int placeCount;
  final bool featured;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<JournalPalette>()!;
    return Semantics(
      button: true,
      label: '${trip.name}, $placeCount Orte',
      child: Card(
        child: InkWell(
          onTap: () => context.push('/trip/${trip.id}'),
          child: SizedBox(
            height: featured ? 280 : 235,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'trip:${trip.id}',
                  child: JournalPhoto(trip.coverId, label: trip.name),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.scrim.withValues(alpha: .06),
                        palette.scrim.withValues(alpha: .82),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: palette.onPhoto.withValues(alpha: .92),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                featured
                                    ? (trip.startDate.isAfter(DateTime.now())
                                          ? 'DEINE NÄCHSTE REISE'
                                          : !trip.endDate.isBefore(
                                              DateUtils.dateOnly(
                                                DateTime.now(),
                                              ),
                                            )
                                          ? 'GERADE UNTERWEGS'
                                          : 'DEINE LETZTE REISE')
                                    : '$placeCount ORTE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: palette.scrim,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.north_east_rounded,
                            color: palette.onPhoto,
                            size: 21,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        trip.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: palette.onPhoto),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: palette.onPhoto,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              dateRange(trip.startDate, trip.endDate),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.onPhoto),
                            ),
                          ),
                          if (featured) ...[
                            const SizedBox(width: 12),
                            Text(
                              '·  $placeCount Orte',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.onPhoto),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
