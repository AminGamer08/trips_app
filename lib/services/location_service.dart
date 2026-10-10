import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/journal.dart';
import '../utilities/app_exception.dart';

abstract interface class LocationService {
  Future<Coordinates> currentPosition();
}

class DeviceLocationService implements LocationService {
  @override
  Future<Coordinates> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException(
          'Der Standortdienst ist ausgeschaltet. Aktiviere ihn in den Geräteeinstellungen oder wähle einen Punkt auf der Karte.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          'Der Standortzugriff ist gesperrt. Du kannst ihn in den App-Einstellungen deines Geräts erlauben oder Koordinaten manuell eingeben.',
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        throw const AppException(
          'Ohne Standortfreigabe kannst du einen Punkt auf der Karte wählen oder die Koordinaten selbst eingeben.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Dein Standort konnte gerade nicht ermittelt werden. Bitte versuche es draußen noch einmal.',
      );
    } catch (_) {
      throw const AppException(
        'Der Standort ist gerade nicht verfügbar. Du kannst die Karte oder manuelle Koordinaten verwenden.',
      );
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => DeviceLocationService(),
);
