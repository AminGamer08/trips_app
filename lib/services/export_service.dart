import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/journal_repository.dart';
import '../utilities/app_exception.dart';

class ExportService {
  Future<String> createJson(JournalRepository repository) async {
    final data = await repository.exportData();
    final assetIds = <String>{};
    for (final p in data['places'] as List) {
      assetIds.addAll(
        (p['photoIds'] as List).cast<String>().where(
          (id) => id.startsWith('asset:'),
        ),
      );
    }
    for (final t in data['trips'] as List) {
      final id = t['coverId'] as String?;
      if (id != null && id.startsWith('asset:')) {
        assetIds.add(id);
      }
    }
    final photos = [...data['photos'] as List];
    final missing = <String>[];
    for (final id in assetIds) {
      try {
        final bytes = await rootBundle.load(id.substring(6));
        photos.add({
          'id': id,
          'encoding': 'base64',
          'data': base64Encode(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          ),
        });
      } catch (_) {
        missing.add(id);
      }
    }
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({...data, 'photos': photos, 'missingPhotos': missing});
  }

  Future<void> share(JournalRepository repository, Rect origin) async {
    try {
      final json = await createJson(repository);
      final name =
          'adventure-journal-${DateTime.now().toIso8601String().substring(0, 10)}.json';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(json)),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: [name],
          subject: 'Mein Adventure Journal',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      throw const AppException(
        'Der Export konnte nicht erstellt werden. Bitte prüfe den freien Speicher und versuche es erneut.',
      );
    }
  }
}
