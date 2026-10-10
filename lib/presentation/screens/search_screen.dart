import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../state/journal_provider.dart';
import '../../utilities/formatters.dart';
import '../widgets/common.dart';
import '../widgets/place_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _query = TextEditingController(
    text: ref.read(searchFilterProvider).query,
  );
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Deine Erinnerungen')),
    body: JournalAsync(
      builder: (data) {
        final filter = ref.watch(searchFilterProvider),
            results = ref.watch(searchFilterProvider).apply(data.places);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: SearchBar(
                controller: _query,
                hintText: 'Ort, Stadt, Land oder Erinnerung',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) => ref
                    .read(searchFilterProvider.notifier)
                    .update(filter.withQuery(value)),
                trailing: [
                  if (_query.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Suche leeren',
                      onPressed: () {
                        _query.clear();
                        ref
                            .read(searchFilterProvider.notifier)
                            .update(filter.withQuery(''));
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${results.length} ${results.length == 1 ? 'Erinnerung' : 'Erinnerungen'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Badge(
                    isLabelVisible: filter.activeCount > 0,
                    label: Text('${filter.activeCount}'),
                    child: TextButton.icon(
                      onPressed: () async {
                        final updated = await showModalBottomSheet<PlaceFilter>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => _FilterSheet(
                            initial: filter,
                            countries:
                                data.places
                                    .map((p) => p.country)
                                    .toSet()
                                    .toList()
                                  ..sort(),
                          ),
                        );
                        if (updated != null && mounted) {
                          ref
                              .read(searchFilterProvider.notifier)
                              .update(updated);
                        }
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Filter'),
                    ),
                  ),
                ],
              ),
            ),
            if (filter.activeCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final category in filter.categories)
                        InputChip(
                          label: Text(category.label),
                          onDeleted: () => ref
                              .read(searchFilterProvider.notifier)
                              .update(
                                PlaceFilter(
                                  query: filter.query,
                                  categories: {...filter.categories}
                                    ..remove(category),
                                  country: filter.country,
                                  minimumRating: filter.minimumRating,
                                  from: filter.from,
                                  to: filter.to,
                                ),
                              ),
                        ),
                      ActionChip(
                        label: const Text('Filter zurücksetzen'),
                        onPressed: () => ref
                            .read(searchFilterProvider.notifier)
                            .update(PlaceFilter(query: filter.query)),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: Icons.travel_explore_rounded,
                      title: 'Noch keine Spur gefunden',
                      message:
                          'Versuche einen anderen Suchbegriff oder passe deine Filter an.',
                      action: 'Suche zurücksetzen',
                      onAction: () {
                        _query.clear();
                        ref
                            .read(searchFilterProvider.notifier)
                            .update(const PlaceFilter());
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: PlaceTile(results[i]),
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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.countries});
  final PlaceFilter initial;
  final List<String> countries;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<PlaceCategory> _categories = {...widget.initial.categories};
  late String? _country = widget.initial.country;
  late int _rating = widget.initial.minimumRating;
  late DateTime? _from = widget.initial.from, _to = widget.initial.to;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: Space.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Finde deinen Moment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _categories = {};
                  _country = null;
                  _rating = 0;
                  _from = null;
                  _to = null;
                }),
                child: const Text('Zurücksetzen'),
              ),
            ],
          ),
          const SectionHeading('Kategorie'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in PlaceCategory.values)
                FilterChip(
                  label: Text(category.label),
                  avatar: Icon(category.icon, size: 16),
                  selected: _categories.contains(category),
                  onSelected: (selected) => setState(() {
                    selected
                        ? _categories.add(category)
                        : _categories.remove(category);
                  }),
                ),
            ],
          ),
          const SectionHeading('Land'),
          DropdownButtonFormField<String>(
            key: ValueKey(_country),
            initialValue: _country ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Land auswählen'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Alle Länder')),
              for (final country in {...widget.countries, ?_country})
                DropdownMenuItem(value: country, child: Text(country)),
            ],
            onChanged: (country) =>
                setState(() => _country = country == '' ? null : country),
          ),
          const SectionHeading('Mindestens so viele Sterne'),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i <= 5; i++)
                ChoiceChip(
                  label: Text(i == 0 ? 'Alle' : '$i ★'),
                  selected: _rating == i,
                  onSelected: (_) => setState(() => _rating = i),
                ),
            ],
          ),
          const SectionHeading('Zeitraum'),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded),
            label: Text(
              _from == null
                  ? 'Alle Zeiträume'
                  : dateRange(_from!, _to ?? _from!),
            ),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                initialDateRange: _from == null
                    ? null
                    : DateTimeRange(start: _from!, end: _to ?? _from!),
              );
              if (range != null && mounted) {
                setState(() {
                  _from = range.start;
                  _to = range.end;
                });
              }
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                PlaceFilter(
                  query: widget.initial.query,
                  categories: Set.unmodifiable(_categories),
                  country: _country,
                  minimumRating: _rating,
                  from: _from,
                  to: _to,
                ),
              ),
              child: const Text('Erinnerungen anzeigen'),
            ),
          ),
        ],
      ),
    ),
  );
}
