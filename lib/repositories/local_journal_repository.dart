import 'dart:convert';
import 'dart:typed_data';
import 'package:sembast/sembast.dart';
import '../database/demo_data.dart';
import '../models/journal.dart';
import '../utilities/app_exception.dart';
import 'journal_repository.dart';

class LocalJournalRepository implements JournalRepository {
  LocalJournalRepository(this.database);
  final Database database;
  final _places = stringMapStoreFactory.store('places');
  final _trips = stringMapStoreFactory.store('trips');
  final _photos = stringMapStoreFactory.store('photos');
  final _meta = stringMapStoreFactory.store('metadata');
  final _tombstones = stringMapStoreFactory.store('tombstones');
  @override
  Future<void> initialize() => database.transaction((txn) async {
    if (await _meta.record('initialized').exists(txn)) {
      return;
    }
    final demo = DemoData.create();
    for (final p in demo.places) {
      await _places.record(p.id).put(txn, p.toJson());
    }
    for (final t in demo.trips) {
      await _trips.record(t.id).put(txn, t.toJson());
    }
    await _meta.record('settings').put(txn, demo.settings.toJson());
    await _meta.record('initialized').put(txn, {'schemaVersion': 1});
  });
  @override
  Future<JournalData> read() => database.transaction(
    (txn) async => JournalData(
      places:
          (await _places.find(txn)).map((r) => Place.fromJson(r.value)).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      trips:
          (await _trips.find(txn)).map((r) => Trip.fromJson(r.value)).toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate)),
      settings: JournalSettings.fromJson(
        await _meta.record('settings').get(txn) ?? {},
      ),
    ),
  );
  @override
  Future<void> savePlace(
    Place place, {
    Map<String, Uint8List> photos = const {},
  }) async {
    if (place.name.trim().isEmpty ||
        place.city.trim().isEmpty ||
        place.country.trim().isEmpty ||
        !place.coordinates.isValid ||
        place.rating < 1 ||
        place.rating > 5 ||
        place.photoIds.length > 8) {
      throw const AppException(
        'Bitte prüfe Name, Stadt, Land, Koordinaten, Bewertung und Fotos.',
      );
    }
    await database.transaction((txn) async {
      if (place.tripId != null &&
          !await _trips.record(place.tripId!).exists(txn)) {
        throw const AppException(
          'Diese Reise existiert nicht mehr. Bitte wähle eine andere Reise.',
        );
      }
      await _savePhotos(txn, photos);
      await _places.record(place.id).put(txn, place.toJson());
      await _tombstones.record('place:${place.id}').delete(txn);
      await _removeUnusedPhotos(txn);
    });
  }

  @override
  Future<void> deletePlace(String id) => database.transaction((txn) async {
    await _places.record(id).delete(txn);
    await _tombstone(txn, 'place', id);
    await _removeUnusedPhotos(txn);
  });
  @override
  Future<void> saveTrip(
    Trip trip, {
    Map<String, Uint8List> photos = const {},
  }) async {
    if (trip.name.trim().isEmpty || trip.endDate.isBefore(trip.startDate)) {
      throw const AppException(
        'Bitte gib einen Namen und einen gültigen Reisezeitraum an.',
      );
    }
    await database.transaction((txn) async {
      await _savePhotos(txn, photos);
      await _trips.record(trip.id).put(txn, trip.toJson());
      await _tombstones.record('trip:${trip.id}').delete(txn);
      await _removeUnusedPhotos(txn);
    });
  }

  @override
  Future<void> deleteTrip(String id) => database.transaction((txn) async {
    final places = await _places.find(
      txn,
      finder: Finder(filter: Filter.equals('tripId', id)),
    );
    for (final p in places) {
      await _places
          .record(p.key)
          .put(txn, Place.fromJson(p.value).withoutTrip().toJson());
    }
    await _trips.record(id).delete(txn);
    await _tombstone(txn, 'trip', id);
    await _removeUnusedPhotos(txn);
  });
  Future<void> _tombstone(Transaction txn, String type, String id) async {
    await _tombstones.record('$type:$id').put(txn, {
      'id': id,
      'type': type,
      'deletedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Media and metadata commit together. The UI state holds only photo references.
  Future<void> _savePhotos(
    Transaction txn,
    Map<String, Uint8List> photos,
  ) async {
    for (final entry in photos.entries) {
      if (entry.value.length > 5 * 1024 * 1024) {
        throw const AppException(
          'Ein Foto ist zu groß. Bitte wähle ein Bild unter 5 MB.',
        );
      }
      await _photos.record(entry.key).put(txn, {
        'id': entry.key,
        'encoding': 'base64',
        'data': base64Encode(entry.value),
      });
    }
  }

  Future<void> _removeUnusedPhotos(Transaction txn) async {
    final used = <String>{};
    for (final p in await _places.find(txn)) {
      used.addAll((p.value['photoIds'] as List).cast<String>());
    }
    for (final t in await _trips.find(txn)) {
      final id = t.value['coverId'] as String?;
      if (id != null) {
        used.add(id);
      }
    }
    for (final photo in await _photos.findKeys(txn)) {
      if (!used.contains(photo)) {
        await _photos.record(photo).delete(txn);
      }
    }
  }

  @override
  Future<Uint8List?> readPhoto(String id) async {
    final record = await _photos.record(id).get(database);
    if (record == null) {
      return null;
    }
    try {
      return base64Decode(record['data'] as String);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveSettings(JournalSettings settings) async {
    await _meta.record('settings').put(database, settings.toJson());
  }

  @override
  Future<Map<String, Object?>> exportData() => database.transaction(
    (txn) async => {
      'format': 'adventure-journal',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'places': (await _places.find(txn)).map((r) => r.value).toList(),
      'trips': (await _trips.find(txn)).map((r) => r.value).toList(),
      'photos': (await _photos.find(txn)).map((r) => r.value).toList(),
      'settings': await _meta.record('settings').get(txn),
      'tombstones': (await _tombstones.find(txn)).map((r) => r.value).toList(),
    },
  );
  @override
  Future<void> clearData() => database.transaction((txn) async {
    for (final p in await _places.findKeys(txn)) {
      await _tombstone(txn, 'place', p);
    }
    for (final t in await _trips.findKeys(txn)) {
      await _tombstone(txn, 'trip', t);
    }
    await _places.delete(txn);
    await _trips.delete(txn);
    await _photos.delete(txn);
    // Preserve settings and seed marker: clearing must never re-seed demo data.
  });
}
