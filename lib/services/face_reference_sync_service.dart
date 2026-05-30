import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_config.dart';
import '../features/face_images/data/face_image_repository.dart';
import '../models/face_image_state.dart';
import 'face_reference_store.dart';

class MissingFaceReferencesException implements Exception {
  const MissingFaceReferencesException();
}

class FaceReferencePreparationException implements Exception {
  const FaceReferencePreparationException(this.message);

  final String message;
}

class FaceReferenceSyncService {
  FaceReferenceSyncService({
    required FaceImageRepository faceImageRepository,
    required Dio dio,
    required FaceReferenceStore store,
  }) : _faceImageRepository = faceImageRepository,
       _dio = dio,
       _downloadDio = Dio(
         BaseOptions(
           connectTimeout: AppConfig.requestTimeout,
           receiveTimeout: AppConfig.requestTimeout,
         ),
       ),
       _store = store;

  final FaceImageRepository _faceImageRepository;
  final Dio _dio;
  final Dio _downloadDio;
  final FaceReferenceStore _store;

  Future<void> rebuild(String userId) async {
    final images = await _faceImageRepository.fetchFaceImages();
    if (!images.isComplete) {
      throw const MissingFaceReferencesException();
    }

    final tempDir = await getTemporaryDirectory();
    final files = <FaceImageSlot, File>{};
    try {
      for (final slot in FaceImageSlot.values) {
        final url = images.imageFor(slot);
        if (url == null || url.isEmpty) {
          throw const MissingFaceReferencesException();
        }
        final file = File(
          '${tempDir.path}${Platform.pathSeparator}face-reference-${slot.apiValue}.jpg',
        );
        final bytes = await _downloadImageBytes(_resolveImageUrl(url));
        if (bytes == null || bytes.isEmpty) {
          throw StateError('Unable to download ${slot.label} face image.');
        }
        await file.writeAsBytes(bytes, flush: true);
        files[slot] = file;
      }

      final registeredCount = await _store.replaceReferences(
        userId: userId,
        imagePaths: {
          for (final entry in files.entries) entry.key: entry.value.path,
        },
      );
      if (registeredCount == 0) {
        throw const FaceReferencePreparationException(
          'Unable to detect a usable face in the uploaded images. Please update your front face image.',
        );
      }
    } finally {
      for (final file in files.values) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  Future<List<int>?> _downloadImageBytes(String url) async {
    try {
      final response = await _downloadDio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    }
  }

  String _resolveImageUrl(String rawUrl) {
    final value = rawUrl.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final base = Uri.parse(AppConfig.apiBaseUrl);
    final origin = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
    );
    final path = value.startsWith('/') ? value : '/$value';
    return origin.replace(path: path).toString();
  }
}
