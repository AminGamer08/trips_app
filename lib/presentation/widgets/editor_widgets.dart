import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../services/photo_service.dart';
import '../../utilities/app_exception.dart';
import 'common.dart';
import 'journal_photo.dart';

class EditorScaffold extends StatefulWidget {
  const EditorScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.dirty,
    required this.busy,
    required this.onSave,
    this.saveLabel = 'Erinnerung speichern',
  });
  final String title, saveLabel;
  final Widget child;
  final bool dirty, busy;
  final VoidCallback onSave;
  @override
  State<EditorScaffold> createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<EditorScaffold> {
  bool _leave = false, _asking = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: (!widget.dirty || _leave) && !widget.busy,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || widget.busy || _asking) {
        return;
      }
      _asking = true;
      final confirmed = await confirmAction(
        context,
        title: 'Änderungen verwerfen?',
        message: 'Deine ungespeicherten Änderungen gehen verloren.',
        action: 'Verwerfen',
      );
      _asking = false;
      if (confirmed && mounted) {
        setState(() => _leave = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton.icon(
            key: const Key('editor-save'),
            onPressed: widget.busy ? null : widget.onSave,
            icon: widget.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(widget.busy ? 'Wird gespeichert …' : widget.saveLabel),
          ),
        ),
      ),
    ),
  );
}

class PhotoInput extends ConsumerStatefulWidget {
  const PhotoInput({
    super.key,
    required this.ids,
    required this.pending,
    required this.onChanged,
    this.limit = 8,
  });
  final List<String> ids;
  final Map<String, Uint8List> pending;
  final void Function(List<String> ids, Map<String, Uint8List> pending)
  onChanged;
  final int limit;
  @override
  ConsumerState<PhotoInput> createState() => _PhotoInputState();
}

class _PhotoInputState extends ConsumerState<PhotoInput> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final recovered = await ref
            .read(photoServiceProvider)
            .recoverLostPhotos();
        if (mounted && recovered.isNotEmpty) {
          final photos = Map.fromEntries(
            recovered.entries.take(widget.limit - widget.ids.length),
          );
          widget.onChanged(
            [...widget.ids, ...photos.keys],
            {...widget.pending, ...photos},
          );
          showMessage(
            context,
            'Deine unterbrochene Fotoauswahl wurde wiederhergestellt.',
          );
        }
      } catch (e) {
        if (mounted) {
          showMessage(context, friendlyError(e));
        }
      }
    });
  }

  Future<void> _pick(bool camera) async {
    setState(() => _busy = true);
    try {
      final photos = await ref
          .read(photoServiceProvider)
          .pick(camera: camera, limit: widget.limit - widget.ids.length);
      if (mounted && photos.isNotEmpty) {
        widget.onChanged(
          [...widget.ids, ...photos.keys],
          {...widget.pending, ...photos},
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.ids.isNotEmpty)
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.ids.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => SizedBox(
              width: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: Space.smallRadius,
                    child: JournalPhoto(
                      widget.ids[i],
                      bytes: widget.pending[widget.ids[i]],
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: IconButton.filledTonal(
                      tooltip: 'Foto entfernen',
                      icon: const Icon(Icons.close_rounded, size: 17),
                      onPressed: _busy
                          ? null
                          : () {
                              final pending = {...widget.pending}
                                ..remove(widget.ids[i]);
                              widget.onChanged(
                                [...widget.ids]..removeAt(i),
                                pending,
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (widget.ids.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: .4),
            borderRadius: Space.radius,
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              const Text('Ein Bild, das dich zurückbringt'),
            ],
          ),
        ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _busy || widget.ids.length >= widget.limit
                ? null
                : () => _pick(false),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: const Text('Galerie'),
          ),
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS))
            OutlinedButton.icon(
              onPressed: _busy || widget.ids.length >= widget.limit
                  ? null
                  : () => _pick(true),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Kamera'),
            ),
          Text(
            '${widget.ids.length}/${widget.limit} Fotos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ],
  );
}

String? requiredField(String? text) =>
    text == null || text.trim().isEmpty ? 'Bitte ausfüllen.' : null;
double? parseCoordinate(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
String? coordinateValidator(String? text, {required bool latitude}) {
  final value = parseCoordinate(text ?? '');
  final limit = latitude ? 90 : 180;
  return value == null || !value.isFinite || value.abs() > limit
      ? 'Wert zwischen −$limit und $limit eingeben.'
      : null;
}
