import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../models/journal.dart';
import '../../services/location_service.dart';
import '../../state/journal_provider.dart';
import '../../utilities/app_exception.dart';
import '../../utilities/formatters.dart';
import '../widgets/common.dart';
import '../widgets/editor_widgets.dart';
import 'detail_screens.dart';
import 'map_screen.dart';

class PlaceFormScreen extends StatelessWidget {
  const PlaceFormScreen({super.key, this.id, this.coordinates, this.tripId});
  final String? id, tripId;
  final Coordinates? coordinates;
  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) => id != null && data.place(id!) == null
        ? const Scaffold(body: MissingRecord())
        : _PlaceEditor(
            place: id == null ? null : data.place(id!),
            trips: data.trips,
            coordinates: coordinates,
            tripId: tripId,
          ),
  );
}

class _PlaceEditor extends ConsumerStatefulWidget {
  const _PlaceEditor({
    this.place,
    required this.trips,
    this.coordinates,
    this.tripId,
  });
  final Place? place;
  final List<Trip> trips;
  final Coordinates? coordinates;
  final String? tripId;
  @override
  ConsumerState<_PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends ConsumerState<_PlaceEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name,
      _description,
      _city,
      _country,
      _lat,
      _lon,
      _notes;
  late DateTime _date;
  late PlaceCategory _category;
  late int _rating;
  String? _trip;
  late List<String> _photoIds;
  Map<String, Uint8List> _photos = {};
  bool _dirty = false, _busy = false, _locating = false;
  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _name = TextEditingController(text: p?.name);
    _description = TextEditingController(text: p?.description);
    _city = TextEditingController(text: p?.city);
    _country = TextEditingController(text: p?.country);
    _notes = TextEditingController(text: p?.notes);
    _lat = TextEditingController(
      text: (p?.latitude ?? widget.coordinates?.latitude)?.toStringAsFixed(6),
    );
    _lon = TextEditingController(
      text: (p?.longitude ?? widget.coordinates?.longitude)?.toStringAsFixed(6),
    );
    _trip = p?.tripId ?? widget.tripId;
    if (!widget.trips.any((t) => t.id == _trip)) {
      _trip = null;
    }
    _date =
        p?.visitedAt ??
        widget.trips.where((t) => t.id == _trip).firstOrNull?.startDate ??
        DateTime.now();
    _category = p?.category ?? PlaceCategory.other;
    _rating = p?.rating ?? 5;
    _photoIds = [...?p?.photoIds];
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _city,
      _country,
      _lat,
      _lon,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  void _setCoordinates(Coordinates coordinates) {
    _lat.text = coordinates.latitude.toStringAsFixed(6);
    _lon.text = coordinates.longitude.toStringAsFixed(6);
    _changed();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final coordinates = await ref
          .read(locationServiceProvider)
          .currentPosition();
      if (mounted) {
        _setCoordinates(coordinates);
        showMessage(
          context,
          'Standort übernommen. Ergänze noch Stadt und Land.',
        );
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      showMessage(context, 'Bitte prüfe die markierten Felder.');
      return;
    }
    setState(() => _busy = true);
    final now = DateTime.now().toUtc();
    final place = Place(
      id: widget.place?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      latitude: parseCoordinate(_lat.text)!,
      longitude: parseCoordinate(_lon.text)!,
      city: _city.text.trim(),
      country: _country.text.trim(),
      visitedAt: _date,
      category: _category,
      rating: _rating,
      photoIds: _photoIds,
      notes: _notes.text.trim(),
      tripId: _trip,
      createdAt: widget.place?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await ref
          .read(journalProvider.notifier)
          .savePlace(place, photos: _photos);
      if (mounted) {
        setState(() {
          _dirty = false;
          _busy = false;
        });
        showMessage(context, 'Deine Erinnerung ist gespeichert.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.canPop() ? context.pop() : context.go('/place/${place.id}');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, friendlyError(e));
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() {
        _date = DateTime(
          date.year,
          date.month,
          date.day,
          _date.hour,
          _date.minute,
        );
        _dirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => EditorScaffold(
    title: widget.place == null
        ? 'Einen Ort festhalten'
        : 'Erinnerung bearbeiten',
    dirty: _dirty,
    busy: _busy,
    onSave: _save,
    child: AbsorbPointer(
      absorbing: _busy,
      child: Form(
        key: _form,
        onChanged: _changed,
        child: JournalPage(
          children: [
            Text(
              'Was möchtest du nicht vergessen?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ein Lieblingsplatz. Ein besonderer Moment. Deine Geschichte.',
            ),
            const SizedBox(height: 26),
            PhotoInput(
              ids: _photoIds,
              pending: _photos,
              onChanged: (ids, photos) => setState(() {
                _photoIds = ids;
                _photos = photos;
                _dirty = true;
              }),
            ),
            const SectionHeading('Dein Erinnerungsort'),
            TextFormField(
              key: const Key('place-name'),
              controller: _name,
              validator: requiredField,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Name des Ortes *',
                hintText: 'Zum Beispiel: mein Lieblingscafé',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 3000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Was macht diesen Ort besonders?',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('place-city'),
              controller: _city,
              validator: requiredField,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Stadt *',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('place-country'),
              controller: _country,
              validator: requiredField,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Land *',
                prefixIcon: Icon(Icons.public_rounded),
              ),
            ),
            const SectionHeading('Der Punkt auf deiner Karte'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _locating ? null : _locate,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: const Text('Mein Standort'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final lat = parseCoordinate(_lat.text),
                        lon = parseCoordinate(_lon.text);
                    final initial =
                        lat != null &&
                            lon != null &&
                            Coordinates(lat, lon).isValid
                        ? Coordinates(lat, lon)
                        : null;
                    final point = await pickMapPoint(context, initial: initial);
                    if (point != null && mounted) {
                      _setCoordinates(point);
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Karte wählen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('place-latitude'),
              controller: _lat,
              validator: (v) => coordinateValidator(v, latitude: true),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Breitengrad (Latitude) *',
                hintText: '48.858400',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('place-longitude'),
              controller: _lon,
              validator: (v) => coordinateValidator(v, latitude: false),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Längengrad (Longitude) *',
                hintText: '2.294500',
              ),
            ),
            const SectionHeading('Wann warst du hier?'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(dateLabel(_date)),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_date),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _date = DateTime(
                          _date.year,
                          _date.month,
                          _date.day,
                          time.hour,
                          time.minute,
                        );
                        _dirty = true;
                      });
                    }
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(timeLabel(_date)),
                ),
              ],
            ),
            const SectionHeading('Welche Art von Lieblingsplatz?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in PlaceCategory.values)
                  ChoiceChip(
                    label: Text(category.label),
                    avatar: Icon(category.icon, size: 18),
                    selected: _category == category,
                    onSelected: (_) => setState(() {
                      _category = category;
                      _dirty = true;
                    }),
                  ),
              ],
            ),
            const SectionHeading('Deine persönliche Bewertung'),
            Wrap(
              children: [
                for (var rating = 1; rating <= 5; rating++)
                  IconButton(
                    tooltip: '$rating Sterne',
                    onPressed: () => setState(() {
                      _rating = rating;
                      _dirty = true;
                    }),
                    icon: Icon(
                      rating <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
            const SectionHeading('Teil einer Reise'),
            DropdownButtonFormField<String>(
              initialValue: _trip ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Reise zuordnen'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Einzelne Erinnerung'),
                ),
                for (final trip in widget.trips)
                  DropdownMenuItem(
                    value: trip.id,
                    child: Text(trip.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() {
                _trip = value == '' ? null : value;
                _dirty = true;
              }),
            ),
            const SectionHeading('Nur für dich'),
            TextFormField(
              controller: _notes,
              maxLines: 4,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Persönliche Notizen',
                hintText: 'Was du deinem zukünftigen Ich erzählen möchtest …',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
