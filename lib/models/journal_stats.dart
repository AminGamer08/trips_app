import 'dart:math';
import 'journal.dart';

class JournalStats {
  JournalStats(this.places, this.trips);
  final List<Place> places;
  final List<Trip> trips;
  int get countries =>
      places.map((p) => p.country.trim().toLowerCase()).toSet().length;
  int get cities => places
      .map((p) => '${p.country.trim()}/${p.city.trim()}'.toLowerCase())
      .toSet()
      .length;
  double get averageRating => places.isEmpty
      ? 0
      : places.fold(0, (sum, p) => sum + p.rating) / places.length;
  int get photos => places.fold(0, (sum, p) => sum + p.photoIds.length);
  Map<PlaceCategory, int> get categories => {
    for (final category in PlaceCategory.values)
      category: places.where((p) => p.category == category).length,
  };
  Map<int, int> get tripsByYear {
    final years = <int, int>{};
    for (final t in trips) {
      years.update(t.startDate.year, (v) => v + 1, ifAbsent: () => 1);
    }
    return Map.fromEntries(
      years.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Map<String, int> get topCountries {
    final counts = <String, int>{};
    for (final p in places) {
      counts.update(p.country, (v) => v + 1, ifAbsent: () => 1);
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Straight-line distances between chronological visits, never a routing claim.
  double get distanceKm {
    double distance = 0;
    for (final t in trips) {
      final stops = places.where((p) => p.tripId == t.id).toList()
        ..sort((a, b) => a.visitedAt.compareTo(b.visitedAt));
      for (var i = 1; i < stops.length; i++) {
        distance += haversine(stops[i - 1].coordinates, stops[i].coordinates);
      }
    }
    return distance;
  }

  static double haversine(Coordinates a, Coordinates b) {
    double rad(double degrees) => degrees * pi / 180;
    final dLat = rad(b.latitude - a.latitude),
        dLon = rad(b.longitude - a.longitude);
    final h =
        pow(sin(dLat / 2), 2) +
        cos(rad(a.latitude)) * cos(rad(b.latitude)) * pow(sin(dLon / 2), 2);
    return 6371 * 2 * asin(sqrt(h.clamp(0, 1)));
  }
}
