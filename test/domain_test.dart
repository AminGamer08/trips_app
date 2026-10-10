import 'package:adventure_journal/database/demo_data.dart';
import 'package:adventure_journal/models/journal.dart';
import 'package:adventure_journal/models/journal_stats.dart';
import 'package:adventure_journal/presentation/map/offline_map.dart';
import 'package:adventure_journal/presentation/widgets/editor_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final demo = DemoData.create();
  test('Place and Trip JSON preserve every field and stable IDs', () {
    for (final place in demo.places) {
      expect(Place.fromJson(place.toJson()).toJson(), place.toJson());
    }
    for (final trip in demo.trips) {
      expect(Trip.fromJson(trip.toJson()).toJson(), trip.toJson());
    }
  });
  test(
    'Search matches name, city, country and description without case sensitivity',
    () {
      expect(
        const PlaceFilter(query: '  EIFFEL  ').apply(demo.places).single.id,
        'eiffel',
      );
      expect(
        const PlaceFilter(query: 'amsterdam').apply(demo.places).length,
        2,
      );
      expect(const PlaceFilter(query: 'Italien').apply(demo.places).length, 2);
      expect(
        const PlaceFilter(query: 'Morgenlicht').apply(demo.places).single.id,
        'eiffel',
      );
    },
  );
  test(
    'Combined filters include the entire final day and exclude the next day',
    () {
      final filtered = PlaceFilter(
        categories: {PlaceCategory.sightseeing},
        country: 'Frankreich',
        minimumRating: 5,
        from: DateTime(2026, 6, 12),
        to: DateTime(2026, 6, 12),
      ).apply(demo.places);
      expect(filtered.map((p) => p.id), ['louvre', 'eiffel']);
      expect(
        PlaceFilter(
          from: DateTime(2026, 6, 13),
          to: DateTime(2026, 6, 13),
        ).apply(demo.places).map((p) => p.id),
        ['hotel', 'luxembourg'],
      );
    },
  );
  test(
    'Coordinate validation rejects NaN, infinity and out-of-range values',
    () {
      expect(const Coordinates(90, 180).isValid, isTrue);
      expect(const Coordinates(-90, -180).isValid, isTrue);
      expect(const Coordinates(double.nan, 0).isValid, isFalse);
      expect(const Coordinates(0, double.infinity).isValid, isFalse);
      expect(const Coordinates(91, 0).isValid, isFalse);
      expect(coordinateValidator('NaN', latitude: true), isNotNull);
      expect(parseCoordinate(' 48,8584 '), 48.8584);
    },
  );
  test('Mercator round trips coordinates in both hemispheres', () {
    for (final point in [
      const Coordinates(48.8584, 2.2945),
      const Coordinates(-33.86, 151.2),
      const Coordinates(0, -179.9),
    ]) {
      final restored = Mercator.unproject(Mercator.project(point));
      expect(restored.latitude, closeTo(point.latitude, 1e-6));
      expect(restored.longitude, closeTo(point.longitude, 1e-6));
    }
  });
  test('Statistics use actual records and handle an empty journal', () {
    final stats = JournalStats(demo.places, demo.trips);
    expect(stats.countries, 5);
    expect(stats.cities, 5);
    expect(stats.categories.values.reduce((a, b) => a + b), 14);
    expect(stats.tripsByYear, {2025: 2, 2026: 3});
    expect(stats.averageRating, closeTo(4.642857, 1e-5));
    final empty = JournalStats([], []);
    expect(empty.averageRating, 0);
    expect(empty.distanceKm, 0);
    expect(empty.tripsByYear, isEmpty);
  });
  test('Haversine computes distance without a map provider', () {
    expect(
      JournalStats.haversine(const Coordinates(0, 0), const Coordinates(0, 0)),
      0,
    );
    expect(
      JournalStats.haversine(const Coordinates(0, 0), const Coordinates(0, 1)),
      closeTo(111.195, .01),
    );
  });
  test(
    'Settings survive serialization and copy updates leave other preferences intact',
    () {
      final settings = const JournalSettings().copyWith(
        appearance: Appearance.dark,
        unit: DistanceUnit.miles,
      );
      final restored = JournalSettings.fromJson(settings.toJson());
      expect(restored.appearance, Appearance.dark);
      expect(restored.unit, DistanceUnit.miles);
      expect(restored.copyWith(seed: 123).appearance, Appearance.dark);
    },
  );
}
