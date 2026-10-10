import 'dart:convert';
import 'package:adventure_journal/repositories/local_journal_repository.dart';
import 'package:adventure_journal/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Portable export includes every referenced demo image exactly once',
    () async {
      final db = await databaseFactoryMemory.openDatabase('export');
      final repository = LocalJournalRepository(db);
      await repository.initialize();
      final json =
          jsonDecode(await ExportService().createJson(repository)) as Map;
      expect(json['schemaVersion'], 1);
      expect((json['places'] as List).length, 14);
      expect((json['photos'] as List).length, 6);
      expect(json['missingPhotos'], isEmpty);
      final ids = (json['photos'] as List).map((p) => p['id']).toSet();
      for (final place in json['places'] as List) {
        for (final id in place['photoIds'] as List) {
          expect(ids, contains(id));
        }
      }
      for (final photo in json['photos'] as List) {
        expect(base64Decode(photo['data'] as String), isNotEmpty);
      }
      await db.close();
    },
  );
}
