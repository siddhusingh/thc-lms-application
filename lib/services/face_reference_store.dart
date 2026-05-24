import 'package:face_verification/face_verification.dart' as offline_face;
import 'package:flutter/foundation.dart';

import '../models/face_image_state.dart';

class FaceReferenceStore {
  FaceReferenceStore({offline_face.FaceVerification? verification})
    : _verification = verification ?? offline_face.FaceVerification.instance;

  final offline_face.FaceVerification _verification;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _verification.init();
    _initialized = true;
  }

  Future<int> replaceReferences({
    required String userId,
    required Map<FaceImageSlot, String> imagePaths,
  }) async {
    await initialize();
    await _verification.deleteUserFaces(userId);
    var registeredCount = 0;
    for (final entry in imagePaths.entries) {
      try {
        await _verification.registerFromImagePath(
          id: userId,
          imagePath: entry.value,
          imageId: entry.key.apiValue,
          replace: true,
        );
        registeredCount++;
      } catch (error, stackTrace) {
        debugPrint(
          'Unable to register ${entry.key.apiValue} face reference: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    return registeredCount;
  }

  Future<bool> hasReadyReferences(String userId) async {
    await initialize();
    return await _verification.getFaceCountForUser(userId) > 0;
  }

  Future<bool> verify({
    required String userId,
    required String imagePath,
  }) async {
    await initialize();
    final matchedUserId = await _verification.verifyFromImagePath(
      imagePath: imagePath,
      staffId: userId,
    );
    return matchedUserId == userId;
  }
}
