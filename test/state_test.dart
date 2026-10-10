import 'package:adventure_journal/database/demo_data.dart';
import 'package:adventure_journal/models/journal.dart';
import 'package:adventure_journal/repositories/local_journal_repository.dart';
import 'package:adventure_journal/state/journal_provider.dart';
import 'package:adventure_journal/utilities/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test(
    'Queued edits publish current data and recover after a failed mutation',
    () async {
      final db = await databaseFactoryMemory.openDatabase('state-test');
      final repo = LocalJournalRepository(db);
      await repo.initialize();
      final container = ProviderContainer.test(
        overrides: [repositoryProvider.overrideWith((ref) async => repo)],
      );
      final subscription = container.listen(journalProvider, (_, _) {});
      await container.read(journalProvider.future);
      final controller = container.read(journalProvider.notifier),
          source = DemoData.create().places.first;
      final invalid = Place.fromJson({...source.toJson(), 'rating': 7});
      await expectLater(
        controller.savePlace(invalid),
        throwsA(isA<AppException>()),
      );
      expect(container.read(journalProvider).asData!.value.places.length, 14);
      final created = Place.fromJson({...source.toJson(), 'id': 'new'});
      await Future.wait([
        controller.savePlace(created),
        controller.deletePlace('eiffel'),
      ]);
      final data = container.read(journalProvider).asData!.value;
      expect(data.place('new'), isNotNull);
      expect(data.place('eiffel'), isNull);
      expect(data.places.length, 14);
      subscription.close();
      await db.close();
    },
  );
}
