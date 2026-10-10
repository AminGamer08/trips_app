import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../utilities/formatters.dart';
import 'common.dart';
import 'journal_photo.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard(this.place, {super.key});
  final Place place;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => context.push('/place/${place.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'place:${place.id}',
                  child: JournalPhoto(
                    place.photoIds.firstOrNull,
                    label: place.name,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating}.0',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${place.city}, ${place.country}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CategoryBadge(place.category),
                    const Spacer(),
                    Text(
                      shortDate(place.visitedAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PlaceTile extends StatelessWidget {
  const PlaceTile(this.place, {super.key, this.onTap});
  final Place place;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap ?? () => context.push('/place/${place.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: Space.smallRadius,
              child: SizedBox(
                width: 76,
                height: 84,
                child: JournalPhoto(
                  place.photoIds.firstOrNull,
                  label: place.name,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${place.city} · ${shortDate(place.visitedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 7),
                  Stars(place.rating),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    ),
  );
}
