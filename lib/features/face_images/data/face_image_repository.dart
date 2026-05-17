import 'dart:io';

import 'package:image/image.dart' as img;

import '../../../core/api/api_exception.dart';
import '../../../models/face_image_state.dart';
import 'face_image_service.dart';

class FaceImageRepository {
  FaceImageRepository(this._service);

  final FaceImageService _service;

  Future<FaceImageState> fetchFaceImages() => _service.fetchFaceImages();

  Future<FaceImageState> uploadFaceImage({
    required FaceImageSlot slot,
    required File file,
  }) async {
    await _validateImage(file);
    return _service.uploadFaceImage(slot: slot, file: file);
  }

  Future<void> _validateImage(File file) async {
    if (!await file.exists()) {
      throw ApiException('Selected image could not be found.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || img.decodeImage(bytes) == null) {
      throw ApiException('Please choose a valid image file.');
    }
  }
}
