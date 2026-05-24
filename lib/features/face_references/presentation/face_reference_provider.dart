import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../models/face_reference_status.dart';
import '../../../services/face_reference_store.dart';
import '../../../services/face_reference_sync_service.dart';

class FaceReferenceProvider extends ChangeNotifier {
  FaceReferenceProvider({
    required FaceReferenceSyncService syncService,
    required FaceReferenceStore store,
  }) : _syncService = syncService,
       _store = store;

  final FaceReferenceSyncService _syncService;
  final FaceReferenceStore _store;

  FaceReferenceStatus status = const FaceReferenceStatus.idle();
  Future<void>? _syncFuture;
  String? _userId;

  Future<void> prepare(String userId, {bool force = false}) {
    _userId = userId;
    final inFlight = _syncFuture;
    if (inFlight != null) return inFlight;
    if (!force && status.isReady) return Future.value();

    status = const FaceReferenceStatus.preparing();
    notifyListeners();

    final future = _runSync(userId);
    _syncFuture = future.whenComplete(() => _syncFuture = null);
    return _syncFuture!;
  }

  Future<void> retry() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return Future.value();
    return prepare(userId, force: true);
  }

  Future<bool> verifyLocal(File image) async {
    final userId = _userId;
    if (!status.isReady || userId == null || userId.isEmpty) {
      return false;
    }
    return _store.verify(userId: userId, imagePath: image.path);
  }

  Future<void> _runSync(String userId) async {
    try {
      await _syncService.rebuild(userId);
      status = const FaceReferenceStatus.ready();
    } on MissingFaceReferencesException {
      status = const FaceReferenceStatus.missing();
    } on FaceReferencePreparationException catch (exception) {
      status = FaceReferenceStatus.failed(exception.message);
    } catch (_) {
      status = const FaceReferenceStatus.failed(
        'Unable to prepare face verification. Check your connection and retry.',
      );
    } finally {
      notifyListeners();
    }
  }
}
