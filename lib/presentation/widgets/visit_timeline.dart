import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/journal.dart';
import '../../utilities/formatters.dart';
import 'common.dart';
import 'journal_photo.dart';

class VisitTimeline extends StatelessWidget {
  const VisitTimeline(this.places, {super.key});
  final List<Place> places;
  @override
  Widget build(BuildContext context) {
    final ordered = [...places]
      ..sort((a, b) => a.visitedAt.compareTo(b.visitedAt));
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < ordered.length; i++) ...[
          if (i == 0 ||
              DateUtils.dateOnly(ordered[i - 1].visitedAt) !=
                  DateUtils.dateOnly(ordered[i].visitedAt))
            Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel(ordered[i].visitedAt),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 46,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      timeLabel(ordered[i].visitedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      const SizedBox(height: 17),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: scheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 8),
                    child: Card(
                      child: InkWell(
                        onTap: () => context.push('/place/${ordered[i].id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ordered[i].name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    CategoryBadge(ordered[i].category),
                                    const SizedBox(height: 8),
                                    Stars(ordered[i].rating),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 58,
                                  height: 75,
                                  child: JournalPhoto(
                                    ordered[i].photoIds.firstOrNull,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
