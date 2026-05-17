import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/face_image_state.dart';
import '../data/face_image_repository.dart';

class FaceImageProvider extends ChangeNotifier {
  FaceImageProvider(this._repository);

  final FaceImageRepository _repository;
  final Set<FaceImageSlot> _uploadingSlots = {};
  Future<void>? _loadFuture;
  int _imageVersion = 0;

  FaceImageState? images;
  bool loading = false;
  String? error;

  bool isUploading(FaceImageSlot slot) => _uploadingSlots.contains(slot);

  String? imageUrlFor(FaceImageSlot slot) {
    final imageUrl = images?.imageFor(slot);
    if (imageUrl == null) return null;
    if (_imageVersion == 0) return imageUrl;

    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return imageUrl;
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'v': _imageVersion.toString(),
          },
        )
        .toString();
  }

  Future<void> load({bool refresh = false}) {
    final inFlight = _loadFuture;
    if (inFlight != null) return inFlight;

    final future = _load(refresh: refresh);
    _loadFuture = future.whenComplete(() => _loadFuture = null);
    return _loadFuture!;
  }

  Future<void> _load({required bool refresh}) async {
    loading = refresh || images == null;
    error = null;
    notifyListeners();
    try {
      images = await _repository.fetchFaceImages();
      _refreshImageVersion();
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load face images.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> upload(FaceImageSlot slot, File file) async {
    if (_uploadingSlots.contains(slot)) return false;
    _uploadingSlots.add(slot);
    error = null;
    notifyListeners();
    try {
      images = await _repository.uploadFaceImage(slot: slot, file: file);
      _refreshImageVersion();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Unable to upload face image.';
      return false;
    } finally {
      _uploadingSlots.remove(slot);
      notifyListeners();
    }
  }

  void _refreshImageVersion() {
    _imageVersion = DateTime.now().microsecondsSinceEpoch;
  }
}
