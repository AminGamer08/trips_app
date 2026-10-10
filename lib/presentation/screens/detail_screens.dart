import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/journal_stats.dart';
import '../../state/journal_provider.dart';
import '../../utilities/app_exception.dart';
import '../../utilities/formatters.dart';
import '../map/map_provider.dart';
import '../widgets/common.dart';
import '../widgets/journal_photo.dart';
import '../widgets/visit_timeline.dart';

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: JournalAsync(
      builder: (data) {
        final place = data.place(id);
        if (place == null) {
          return const MissingRecord();
        }
        return CustomScrollView(
          slivers: [
            _CoverHeader(
              photoId: place.photoIds.firstOrNull,
              heroTag: 'place:$id',
              title: place.name,
              onEdit: () => context.push('/place/$id/edit'),
              onDelete: () async {
                if (!await confirmAction(
                  context,
                  title: 'Diesen Ort löschen?',
                  message:
                      '„${place.name}“ und seine Fotos werden aus deinem Journal entfernt.',
                )) {
                  return;
                }
                try {
                  await ref.read(journalProvider.notifier).deletePlace(id);
                  if (context.mounted) {
                    context.canPop() ? context.pop() : context.go('/home');
                  }
                } catch (e) {
                  if (context.mounted) {
                    showMessage(context, friendlyError(e));
                  }
                }
              },
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: Space.page.copyWith(bottom: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryBadge(place.category),
                            const Spacer(),
                            Stars(place.rating, size: 22),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          place.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 9),
                        _InfoLine(
                          Icons.location_on_outlined,
                          '${place.city}, ${place.country}',
                        ),
                        const SizedBox(height: 8),
                        _InfoLine(
                          Icons.calendar_today_outlined,
                          '${dateLabel(place.visitedAt)} · ${timeLabel(place.visitedAt)}',
                        ),
                        if (place.tripId != null &&
                            data.trip(place.tripId!) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ActionChip(
                              avatar: const Icon(
                                Icons.flight_takeoff_rounded,
                                size: 17,
                              ),
                              label: Text(data.trip(place.tripId!)!.name),
                              onPressed: () =>
                                  context.push('/trip/${place.tripId}'),
                            ),
                          ),
                        if (place.description.isNotEmpty) ...[
                          const SectionHeading('Ein Moment zum Erinnern'),
                          Text(
                            place.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        if (place.photoIds.isNotEmpty) ...[
                          SectionHeading(
                            'Deine Fotos · ${place.photoIds.length}',
                          ),
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: place.photoIds.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) => GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PhotoGallery(
                                      ids: place.photoIds,
                                      initial: i,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: Space.smallRadius,
                                  child: SizedBox(
                                    width: 180,
                                    child: JournalPhoto(place.photoIds[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SectionHeading('Notiz an mein zukünftiges Ich'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer
                                .withValues(alpha: .4),
                            borderRadius: Space.radius,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                place.notes.isEmpty
                                    ? 'Hier ist noch Platz für die kleinen Dinge, die du nicht vergessen möchtest.'
                                    : place.notes,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        const SectionHeading('Hier warst du'),
                        Card(
                          child: SizedBox(
                            height: 260,
                            child: JournalMap(
                              request: MapRequest(
                                places: [place],
                                center: place.coordinates,
                                selectedId: place.id,
                                initialZoom: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/place/$id/edit'),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Erinnerung bearbeiten'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: JournalAsync(
      builder: (data) {
        final trip = data.trip(id);
        if (trip == null) {
          return const MissingRecord();
        }
        final places = data.placesForTrip(id),
            stats = JournalStats(data.placesForTrip(id), [trip]);
        return CustomScrollView(
          slivers: [
            _CoverHeader(
              photoId: trip.coverId,
              heroTag: 'trip:$id',
              title: trip.name,
              onEdit: () => context.push('/trip/$id/edit'),
              onDelete: () async {
                if (!await confirmAction(
                  context,
                  title: 'Reise löschen?',
                  message:
                      '„${trip.name}“ wird gelöscht. Deine Orte und deren Fotos bleiben im Journal.',
                )) {
                  return;
                }
                try {
                  await ref.read(journalProvider.notifier).deleteTrip(id);
                  if (context.mounted) {
                    context.canPop() ? context.pop() : context.go('/trips');
                  }
                } catch (e) {
                  if (context.mounted) {
                    showMessage(context, friendlyError(e));
                  }
                }
              },
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: Space.page.copyWith(bottom: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EIN KAPITEL DEINES JOURNALS',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1.6,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          trip.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 12),
                        _InfoLine(
                          Icons.calendar_today_outlined,
                          dateRange(trip.startDate, trip.endDate),
                        ),
                        if (trip.description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            trip.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Metric(
                                icon: Icons.location_on_outlined,
                                value: '${places.length}',
                                label: 'Orte',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Metric(
                                icon: Icons.restaurant_rounded,
                                value:
                                    '${places.where((p) => p.category.name == 'food').length}',
                                label: 'Food-Spots',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Metric(
                                icon: Icons.star_outline_rounded,
                                value: places.isEmpty
                                    ? '–'
                                    : decimalLabel(stats.averageRating),
                                label: 'Ø Bewertung',
                              ),
                            ),
                          ],
                        ),
                        const SectionHeading('Deine Reise auf einen Blick'),
                        Card(
                          child: SizedBox(
                            height: 300,
                            child: JournalMap(
                              request: MapRequest(
                                places: places,
                                connectPlaces: true,
                                onPlaceTap: (place) =>
                                    context.push('/place/${place.id}'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verbindungen zeigen die Reihenfolge deiner Besuche.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SectionHeading(
                          'Moment für Moment',
                          action: 'Ort hinzufügen',
                          onAction: () => context.push('/place/new?trip=$id'),
                        ),
                        if (places.isEmpty)
                          EmptyState(
                            icon: Icons.route_outlined,
                            title: 'Deine Reise beginnt hier',
                            message:
                                'Füge einen Ort hinzu und deine Timeline wächst mit.',
                            action: 'Ersten Ort hinzufügen',
                            onAction: () => context.push('/place/new?trip=$id'),
                          )
                        else
                          VisitTimeline(places),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({
    required this.photoId,
    required this.heroTag,
    required this.title,
    required this.onEdit,
    required this.onDelete,
  });
  final String? photoId;
  final String heroTag, title;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) => SliverAppBar(
    expandedHeight: 300,
    pinned: true,
    leading: Padding(
      padding: const EdgeInsets.all(6),
      child: IconButton.filledTonal(
        tooltip: 'Zurück',
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    actions: [
      IconButton.filledTonal(
        tooltip: 'Bearbeiten',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
      const SizedBox(width: 8),
      IconButton.filledTonal(
        tooltip: 'Löschen',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
      const SizedBox(width: 12),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Hero(
        tag: heroTag,
        child: JournalPhoto(photoId, label: title),
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

class MissingRecord extends StatelessWidget {
  const MissingRecord({super.key});
  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.bookmark_remove_outlined,
    title: 'Diese Erinnerung ist nicht mehr hier',
    message: 'Vielleicht wurde sie inzwischen gelöscht.',
    action: 'Zum Journal',
    onAction: () => context.go('/home'),
  );
}

class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key, required this.ids, required this.initial});
  final List<String> ids;
  final int initial;
  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  late final PageController _controller = PageController(
    initialPage: widget.initial,
  );
  late int _index = widget.initial;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${_index + 1} / ${widget.ids.length}')),
    body: PageView.builder(
      controller: _controller,
      itemCount: widget.ids.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) => InteractiveViewer(
        maxScale: 5,
        child: JournalPhoto(widget.ids[i], fit: BoxFit.contain),
      ),
    ),
  );
}
