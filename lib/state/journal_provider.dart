import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/open_database.dart';
import '../models/journal.dart';
import '../repositories/journal_repository.dart';
import '../repositories/local_journal_repository.dart';

final repositoryProvider = FutureProvider<JournalRepository>((ref) async {
  final database = await openJournalDatabase();
  ref.onDispose(() => database.close());
  final repository = LocalJournalRepository(database);
  await repository.initialize();
  return repository;
});
final journalProvider = AsyncNotifierProvider<JournalController, JournalData>(
  JournalController.new,
);

class JournalController extends AsyncNotifier<JournalData> {
  Future<void> _pending = Future.value();
  @override
  Future<JournalData> build() async =>
      (await ref.watch(repositoryProvider.future)).read();
  // Serialize writes to prevent stale refreshes overwriting newer edits.
  Future<void> _mutate(Future<void> Function(JournalRepository) action) {
    final result = _pending.then((_) async {
      final repository = await ref.read(repositoryProvider.future);
      await action(repository);
      final data = await repository.read();
      if (ref.mounted) {
        state = AsyncData(data);
      }
    });
    _pending = result.catchError((Object _) {});
    return result;
  }

  Future<void> savePlace(
    Place place, {
    Map<String, Uint8List> photos = const {},
  }) => _mutate((r) => r.savePlace(place, photos: photos));
  Future<void> deletePlace(String id) => _mutate((r) => r.deletePlace(id));
  Future<void> saveTrip(
    Trip trip, {
    Map<String, Uint8List> photos = const {},
  }) => _mutate((r) => r.saveTrip(trip, photos: photos));
  Future<void> deleteTrip(String id) => _mutate((r) => r.deleteTrip(id));
  Future<void> saveSettings(JournalSettings settings) =>
      _mutate((r) => r.saveSettings(settings));
  Future<void> updateSettings({
    Appearance? appearance,
    DistanceUnit? unit,
    int? seed,
    bool? dynamicColors,
  }) => _mutate((r) async {
    final current = (await r.read()).settings;
    await r.saveSettings(
      current.copyWith(
        appearance: appearance,
        unit: unit,
        seed: seed,
        dynamicColors: dynamicColors,
      ),
    );
  });
  Future<void> clearData() => _mutate((r) => r.clearData());
}

final photoProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
  (ref, id) async => (await ref.watch(repositoryProvider.future)).readPhoto(id),
);

class SearchController extends Notifier<PlaceFilter> {
  @override
  PlaceFilter build() => const PlaceFilter();
  void update(PlaceFilter filter) => state = filter;
}

final searchFilterProvider = NotifierProvider<SearchController, PlaceFilter>(
  SearchController.new,
);
