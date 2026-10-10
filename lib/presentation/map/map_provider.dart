import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/journal.dart';
import 'offline_map.dart';

class MapRequest {
  const MapRequest({
    required this.places,
    this.selectedId,
    this.onPlaceTap,
    this.onCoordinateTap,
    this.center,
    this.currentLocation,
    this.interactive = true,
    this.connectPlaces = false,
    this.initialZoom,
  });
  final List<Place> places;
  final String? selectedId;
  final ValueChanged<Place>? onPlaceTap;
  final ValueChanged<Coordinates>? onCoordinateTap;
  final Coordinates? center, currentLocation;
  final bool interactive, connectPlaces;
  final double? initialZoom;
}

/// Swap this adapter for Google Maps, MapLibre or another provider without
/// changing journal models, coordinate picking or feature screens.
abstract interface class JournalMapProvider {
  Widget buildMap(MapRequest request);
}

class OfflineMapProvider implements JournalMapProvider {
  @override
  Widget buildMap(MapRequest request) => OfflineMap(request: request);
}

final mapProvider = Provider<JournalMapProvider>((ref) => OfflineMapProvider());

class JournalMap extends ConsumerWidget {
  const JournalMap({super.key, required this.request});
  final MapRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(mapProvider).buildMap(request);
}
