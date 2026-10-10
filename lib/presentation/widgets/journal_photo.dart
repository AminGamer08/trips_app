import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/journal_provider.dart';

class JournalPhoto extends ConsumerWidget {
  const JournalPhoto(
    this.id, {
    super.key,
    this.fit = BoxFit.cover,
    this.bytes,
    this.label = 'Reiseerinnerung',
  });
  final String? id;
  final Uint8List? bytes;
  final BoxFit fit;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget fallback() => ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 42,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
    Widget memory(Uint8List bytes) => Image.memory(
      bytes,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      semanticLabel: label,
      errorBuilder: (_, _, _) => fallback(),
    );
    if (bytes != null) {
      return memory(bytes!);
    }
    if (id == null) {
      return fallback();
    }
    if (id!.startsWith('asset:')) {
      return Image.asset(
        id!.substring(6),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        semanticLabel: label,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return ref
        .watch(photoProvider(id!))
        .when(
          data: (data) => data == null ? fallback() : memory(data),
          loading: () => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          error: (_, _) => fallback(),
        );
  }
}
