enum PlaceCategory { food, hotel, nature, sightseeing, event, other }

enum Appearance { system, light, dark }

enum DistanceUnit { kilometers, miles }

class Coordinates {
  const Coordinates(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class Place {
  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.visitedAt,
    required this.category,
    required this.rating,
    required List<String> photoIds,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.tripId,
  }) : photoIds = List.unmodifiable(photoIds);
  final String id, name, description, city, country, notes;
  final double latitude, longitude;
  final DateTime visitedAt, createdAt, updatedAt;
  final PlaceCategory category;
  final int rating;
  final List<String> photoIds;
  final String? tripId;
  Coordinates get coordinates => Coordinates(latitude, longitude);
  Place withoutTrip() => Place.fromJson({
    ...toJson(),
    'tripId': null,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  });
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    'visitedAt': visitedAt.toIso8601String(),
    'category': category.name,
    'rating': rating,
    'photoIds': photoIds,
    'notes': notes,
    'tripId': tripId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory Place.fromJson(Map<String, Object?> json) => Place(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    city: json['city'] as String,
    country: json['country'] as String,
    visitedAt: DateTime.parse(json['visitedAt'] as String),
    category: PlaceCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => PlaceCategory.other,
    ),
    rating: json['rating'] as int,
    photoIds: (json['photoIds'] as List? ?? []).cast<String>(),
    notes: json['notes'] as String? ?? '',
    tripId: json['tripId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.coverId,
  });
  final String id, name, description;
  final String? coverId;
  final DateTime startDate, endDate, createdAt, updatedAt;
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'coverId': coverId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory Trip.fromJson(Map<String, Object?> json) => Trip(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    coverId: json['coverId'] as String?,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class JournalSettings {
  const JournalSettings({
    this.appearance = Appearance.system,
    this.unit = DistanceUnit.kilometers,
    this.seed = 0xff547466,
    this.dynamicColors = false,
  });
  final Appearance appearance;
  final DistanceUnit unit;
  final int seed;
  final bool dynamicColors;
  JournalSettings copyWith({
    Appearance? appearance,
    DistanceUnit? unit,
    int? seed,
    bool? dynamicColors,
  }) => JournalSettings(
    appearance: appearance ?? this.appearance,
    unit: unit ?? this.unit,
    seed: seed ?? this.seed,
    dynamicColors: dynamicColors ?? this.dynamicColors,
  );
  Map<String, Object?> toJson() => {
    'appearance': appearance.name,
    'unit': unit.name,
    'seed': seed,
    'dynamicColors': dynamicColors,
  };
  factory JournalSettings.fromJson(Map<String, Object?> json) =>
      JournalSettings(
        appearance: Appearance.values.firstWhere(
          (v) => v.name == json['appearance'],
          orElse: () => Appearance.system,
        ),
        unit: DistanceUnit.values.firstWhere(
          (v) => v.name == json['unit'],
          orElse: () => DistanceUnit.kilometers,
        ),
        seed: json['seed'] as int? ?? 0xff547466,
        dynamicColors: json['dynamicColors'] as bool? ?? false,
      );
}

class JournalData {
  JournalData({
    required List<Place> places,
    required List<Trip> trips,
    this.settings = const JournalSettings(),
  }) : places = List.unmodifiable(places),
       trips = List.unmodifiable(trips);
  final List<Place> places;
  final List<Trip> trips;
  final JournalSettings settings;
  Place? place(String id) => places.where((p) => p.id == id).firstOrNull;
  Trip? trip(String id) => trips.where((t) => t.id == id).firstOrNull;
  List<Place> placesForTrip(String id) =>
      places.where((p) => p.tripId == id).toList()
        ..sort((a, b) => a.visitedAt.compareTo(b.visitedAt));
}

class PlaceFilter {
  const PlaceFilter({
    this.query = '',
    this.categories = const {},
    this.country,
    this.minimumRating = 0,
    this.from,
    this.to,
  });
  final String query;
  final Set<PlaceCategory> categories;
  final String? country;
  final int minimumRating;
  final DateTime? from, to;
  int get activeCount =>
      categories.length +
      (country == null ? 0 : 1) +
      (minimumRating > 0 ? 1 : 0) +
      (from != null || to != null ? 1 : 0);
  PlaceFilter withQuery(String query) => PlaceFilter(
    query: query,
    categories: categories,
    country: country,
    minimumRating: minimumRating,
    from: from,
    to: to,
  );
  List<Place> apply(Iterable<Place> places) {
    final term = query.trim().toLowerCase();
    final endExclusive = to == null
        ? null
        : DateTime(to!.year, to!.month, to!.day + 1);
    return places.where((p) {
      final searchable = '${p.name} ${p.city} ${p.country} ${p.description}'
          .toLowerCase();
      return (term.isEmpty || searchable.contains(term)) &&
          (categories.isEmpty || categories.contains(p.category)) &&
          (country == null || p.country == country) &&
          p.rating >= minimumRating &&
          (from == null ||
              !p.visitedAt.isBefore(
                DateTime(from!.year, from!.month, from!.day),
              )) &&
          (endExclusive == null || p.visitedAt.isBefore(endExclusive));
    }).toList()..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
  }
}
