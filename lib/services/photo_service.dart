import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../utilities/app_exception.dart';

class PhotoService {
  final _picker = ImagePicker();
  Future<Map<String, Uint8List>> pick({
    bool camera = false,
    int limit = 8,
  }) async {
    try {
      final files = camera
          ? [
              await _picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1600,
                imageQuality: 82,
              ),
            ].nonNulls.toList()
          : await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 82);
      if (files.length > limit) {
        throw AppException(
          'Du kannst noch $limit Fotos hinzufügen. Bitte wähle weniger Bilder.',
        );
      }
      return _read(files);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'Die Fotos konnten nicht geöffnet werden. Prüfe die Foto- oder Kamerafreigabe in deinen Geräteeinstellungen.',
      );
    }
  }

  Future<Map<String, Uint8List>> recoverLostPhotos() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return {};
    }
    final result = await _picker.retrieveLostData();
    if (result.exception != null) {
      throw const AppException(
        'Die unterbrochene Fotoauswahl konnte nicht wiederhergestellt werden. Bitte wähle die Fotos erneut.',
      );
    }
    return _read(result.files ?? []);
  }

  Future<Map<String, Uint8List>> _read(List<XFile> files) async {
    final result = <String, Uint8List>{};
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw const AppException(
          'Bitte wähle lesbare Fotos mit höchstens 5 MB pro Bild.',
        );
      }
      try {
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 32);
        final frame = await codec.getNextFrame();
        frame.image.dispose();
        codec.dispose();
      } catch (_) {
        throw const AppException(
          'Dieses Bildformat konnte nicht gelesen werden. Bitte verwende JPEG oder PNG.',
        );
      }
      result[const Uuid().v4()] = bytes;
    }
    return result;
  }
}

final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService());
