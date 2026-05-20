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
  int _loadGeneration = 0;
  String? _ownerKey;

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

  Future<void> load({bool refresh = false, String? ownerKey}) {
    if (ownerKey != null && ownerKey != _ownerKey) {
      _clearState(notify: false);
      _ownerKey = ownerKey;
      refresh = true;
    }
    if (!refresh && images != null) return Future.value();
    final inFlight = _loadFuture;
    if (inFlight != null) return inFlight;

    final generation = _loadGeneration;
    final future = _load(refresh: refresh, generation: generation);
    _loadFuture = future.whenComplete(() => _loadFuture = null);
    return _loadFuture!;
  }

  Future<void> _load({required bool refresh, required int generation}) async {
    loading = refresh || images == null;
    error = null;
    notifyListeners();
    try {
      final nextImages = await _repository.fetchFaceImages();
      if (generation != _loadGeneration) return;
      images = nextImages;
      _refreshImageVersion();
    } on ApiException catch (exception) {
      if (generation != _loadGeneration) return;
      error = exception.message;
    } catch (_) {
      if (generation != _loadGeneration) return;
      error = 'Unable to load face images.';
    } finally {
      if (generation == _loadGeneration) {
        loading = false;
        notifyListeners();
      }
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

  void clear() {
    _ownerKey = null;
    _clearState();
  }

  void _clearState({bool notify = true}) {
    _loadGeneration++;
    images = null;
    error = null;
    _uploadingSlots.clear();
    _loadFuture = null;
    _imageVersion = 0;
    if (notify) notifyListeners();
  }
}
