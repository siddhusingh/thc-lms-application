import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../models/face_verification_result.dart';
import '../services/face_verification_service.dart';

class FaceVerificationController extends ChangeNotifier {
  FaceVerificationController(this._service);

  final FaceVerificationService _service;

  CameraController? cameraController;
  FaceVerificationResult? lastResult;
  bool initializing = false;
  bool verifying = false;

  Future<FaceVerificationResult> initializeCamera() async {
    if (cameraController?.value.isInitialized == true) {
      return FaceVerificationResult.verified(message: 'Camera ready.');
    }

    initializing = true;
    lastResult = null;
    notifyListeners();

    try {
      final allowed = await _service.ensureCameraPermission();
      if (!allowed) {
        return _setResult(
          FaceVerificationResult.failed('Camera permission is required.'),
        );
      }

      final cameras = await _service.frontCameras();
      if (cameras.isEmpty) {
        return _setResult(
          FaceVerificationResult.failed('No camera found on this device.'),
        );
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await cameraController?.dispose();
      cameraController = controller;
      return _setResult(
        FaceVerificationResult.verified(message: 'Camera ready.'),
      );
    } catch (_) {
      return _setResult(
        FaceVerificationResult.failed('Unable to start the front camera.'),
      );
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<FaceVerificationResult> verify({required String context}) async {
    final ready = await initializeCamera();
    if (!ready.isVerified) return ready;

    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return _setResult(FaceVerificationResult.failed('Camera is not ready.'));
    }

    verifying = true;
    notifyListeners();
    try {
      final image = await controller.takePicture();
      return _setResult(
        await _service.verifyCapture(image: image, context: context),
      );
    } catch (_) {
      return _setResult(
        FaceVerificationResult.failed('Face verification failed. Try again.'),
      );
    } finally {
      verifying = false;
      notifyListeners();
    }
  }

  FaceVerificationResult _setResult(FaceVerificationResult result) {
    lastResult = result;
    notifyListeners();
    return result;
  }

  Future<void> disposeCamera() async {
    final controller = cameraController;
    cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    unawaited(_service.dispose());
    super.dispose();
  }
}
