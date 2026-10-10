import 'dart:io';
import 'dart:typed_data';
import 'package:adventure_journal/database/demo_data.dart';
import 'package:adventure_journal/models/journal.dart';
import 'package:adventure_journal/repositories/local_journal_repository.dart';
import 'package:adventure_journal/utilities/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/sembast_io.dart';

void main() {
  late Database database;
  late LocalJournalRepository repository;
  setUp(() async {
    database = await databaseFactoryMemory.openDatabase(
      'journal-${DateTime.now().microsecondsSinceEpoch}',
    );
    repository = LocalJournalRepository(database);
    await repository.initialize();
  });
  tearDown(() async => database.close());
  test('Seeding is atomic and happens only once', () async {
    await repository.initialize();
    expect((await repository.read()).places.length, 14);
    expect((await repository.read()).trips.length, 5);
  });
  test('Create, update and delete round trip together with media', () async {
    final source = DemoData.create().places.first;
    final place = Place.fromJson({
      ...source.toJson(),
      'id': 'new',
      'photoIds': ['photo'],
    });
    final bytes = Uint8List.fromList([1, 2, 3]);
    await repository.savePlace(place, photos: {'photo': bytes});
    expect((await repository.read()).place('new')?.name, source.name);
    expect(await repository.readPhoto('photo'), bytes);
    await repository.savePlace(
      Place.fromJson({
        ...place.toJson(),
        'name': 'Updated',
        'photoIds': <String>[],
      }),
    );
    expect((await repository.read()).place('new')?.name, 'Updated');
    expect(await repository.readPhoto('photo'), isNull);
    await repository.deletePlace('new');
    expect((await repository.read()).place('new'), isNull);
    expect(
      (await repository.exportData())['tombstones'],
      contains(containsPair('id', 'new')),
    );
  });
  test('An invalid place never changes the database', () async {
    final bad = Place.fromJson({
      ...DemoData.create().places.first.toJson(),
      'latitude': double.nan,
    });
    await expectLater(repository.savePlace(bad), throwsA(isA<AppException>()));
    expect((await repository.read()).places.length, 14);
    expect((await repository.read()).place(bad.id)!.latitude, isNot(isNaN));
  });
  test('Oversized photo rolls back all media and record writes', () async {
    final p = Place.fromJson({
      ...DemoData.create().places.first.toJson(),
      'id': 'broken',
      'photoIds': ['small', 'big'],
    });
    await expectLater(
      repository.savePlace(
        p,
        photos: {'small': Uint8List(2), 'big': Uint8List(5 * 1024 * 1024 + 1)},
      ),
      throwsA(isA<AppException>()),
    );
    expect((await repository.read()).place('broken'), isNull);
    expect(await repository.readPhoto('small'), isNull);
  });
  test(
    'Deleting a trip keeps its places and removes their association',
    () async {
      await repository.deleteTrip('paris');
      final data = await repository.read();
      expect(data.trips.length, 4);
      expect(data.places.length, 14);
      expect(data.place('eiffel')!.tripId, isNull);
      expect(data.place('eiffel')!.photoIds, isNotEmpty);
    },
  );
  test('Missing trip references are rejected', () async {
    final p = Place.fromJson({
      ...DemoData.create().places.first.toJson(),
      'tripId': 'missing',
    });
    await expectLater(repository.savePlace(p), throwsA(isA<AppException>()));
  });
  test('Trip date validation rejects reversed dates', () async {
    final trip = Trip.fromJson({
      ...DemoData.create().trips.first.toJson(),
      'endDate': '2020-01-01',
    });
    await expectLater(repository.saveTrip(trip), throwsA(isA<AppException>()));
  });
  test('Clearing keeps preferences and never re-seeds demo data', () async {
    await repository.saveSettings(
      const JournalSettings(appearance: Appearance.dark),
    );
    await repository.clearData();
    await repository.initialize();
    final data = await repository.read();
    expect(data.places, isEmpty);
    expect(data.trips, isEmpty);
    expect(data.settings.appearance, Appearance.dark);
    expect(await repository.readPhoto('missing'), isNull);
    final export = await repository.exportData();
    expect(export['schemaVersion'], 1);
    expect(export['format'], 'adventure-journal');
  });
  test(
    'Disk persistence survives closing and reopening the repository',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'adventure-journal-test-',
      );
      final path = '${directory.path}/journal.db';
      final first = await databaseFactoryIo.openDatabase(path);
      final repo = LocalJournalRepository(first);
      await repo.initialize();
      await repo.deletePlace('eiffel');
      await repo.saveSettings(
        const JournalSettings(appearance: Appearance.dark),
      );
      await first.close();
      final reopened = await databaseFactoryIo.openDatabase(path);
      final restored = LocalJournalRepository(reopened);
      await restored.initialize();
      expect((await restored.read()).place('eiffel'), isNull);
      expect((await restored.read()).settings.appearance, Appearance.dark);
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );
}
