import 'dart:typed_data';
import '../models/journal.dart';

/// Stable IDs, timestamps and tombstones allow a future sync adapter.
abstract interface class JournalRepository {
  Future<void> initialize();
  Future<JournalData> read();
  Future<void> savePlace(
    Place place, {
    Map<String, Uint8List> photos = const {},
  });
  Future<void> deletePlace(String id);
  Future<void> saveTrip(Trip trip, {Map<String, Uint8List> photos = const {}});
  Future<void> deleteTrip(String id);
  Future<void> saveSettings(JournalSettings settings);
  Future<Uint8List?> readPhoto(String id);
  Future<Map<String, Object?>> exportData();
  Future<void> clearData();
}
