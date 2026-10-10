import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/journal.dart';
import '../../state/journal_provider.dart';
import '../../utilities/app_exception.dart';
import '../../utilities/formatters.dart';
import '../widgets/common.dart';
import '../widgets/editor_widgets.dart';
import 'detail_screens.dart';

class TripFormScreen extends StatelessWidget {
  const TripFormScreen({super.key, this.id});
  final String? id;
  @override
  Widget build(BuildContext context) => JournalAsync(
    builder: (data) => id != null && data.trip(id!) == null
        ? const Scaffold(body: MissingRecord())
        : _TripEditor(trip: id == null ? null : data.trip(id!)),
  );
}

class _TripEditor extends ConsumerStatefulWidget {
  const _TripEditor({this.trip});
  final Trip? trip;
  @override
  ConsumerState<_TripEditor> createState() => _TripEditorState();
}

class _TripEditorState extends ConsumerState<_TripEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.trip?.name);
  late final _description = TextEditingController(
    text: widget.trip?.description,
  );
  late DateTime _start =
      widget.trip?.startDate ?? DateUtils.dateOnly(DateTime.now());
  late DateTime _end =
      widget.trip?.endDate ?? _start.add(const Duration(days: 3));
  late List<String> _ids = widget.trip?.coverId == null
      ? []
      : [widget.trip!.coverId!];
  Map<String, Uint8List> _photos = {};
  bool _busy = false, _dirty = false;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final now = DateTime.now().toUtc();
    final trip = Trip(
      id: widget.trip?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      startDate: _start,
      endDate: _end,
      coverId: _ids.firstOrNull,
      createdAt: widget.trip?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await ref.read(journalProvider.notifier).saveTrip(trip, photos: _photos);
      if (mounted) {
        setState(() {
          _dirty = false;
          _busy = false;
        });
        showMessage(context, 'Deine Reise ist gespeichert.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.canPop() ? context.pop() : context.go('/trip/${trip.id}');
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

  @override
  Widget build(BuildContext context) => EditorScaffold(
    title: widget.trip == null ? 'Ein neues Abenteuer' : 'Reise bearbeiten',
    dirty: _dirty,
    busy: _busy,
    onSave: _save,
    saveLabel: 'Reise speichern',
    child: AbsorbPointer(
      absorbing: _busy,
      child: Form(
        key: _form,
        onChanged: () {
          if (!_dirty) {
            setState(() => _dirty = true);
          }
        },
        child: JournalPage(
          children: [
            Text(
              'Wohin zieht es dich?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Gib deinem nächsten Kapitel einen Namen.'),
            const SizedBox(height: 24),
            PhotoInput(
              ids: _ids,
              pending: _photos,
              limit: 1,
              onChanged: (ids, photos) => setState(() {
                _ids = ids;
                _photos = photos;
                _dirty = true;
              }),
            ),
            const SectionHeading('Deine Reise'),
            TextFormField(
              key: const Key('trip-name'),
              controller: _name,
              validator: requiredField,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name der Reise *',
                hintText: 'Ein Wochenende in Paris',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 3000,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Worauf freust du dich? Was bleibt in Erinnerung?',
              ),
            ),
            const SectionHeading('Zeit für ein Abenteuer'),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const Icon(Icons.date_range_rounded),
                title: Text(dateRange(_start, _end)),
                subtitle: Text(
                  '${_end.difference(_start).inDays + 1} Tage unterwegs',
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                    initialDateRange: DateTimeRange(start: _start, end: _end),
                  );
                  if (range != null && mounted) {
                    setState(() {
                      _start = range.start;
                      _end = range.end;
                      _dirty = true;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gespeicherte Orte kannst du im Ort-Formular dieser Reise zuordnen.',
            ),
          ],
        ),
      ),
    ),
  );
}
