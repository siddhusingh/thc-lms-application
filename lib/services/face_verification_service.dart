import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/face_verification_result.dart';

typedef BackendFaceVerifier =
    Future<FaceVerificationResult> Function(File image, String context);

class FaceVerificationService {
  FaceVerificationService({
    required BackendFaceVerifier backendVerifier,
    this.similarityThreshold = 0.75,
    this.minFaceSizePx = 80,
  }) : _backendVerifier = backendVerifier,
       _faceDetector = FaceDetector(
         options: FaceDetectorOptions(
           enableClassification: true,
           enableLandmarks: true,
           performanceMode: FaceDetectorMode.accurate,
         ),
       );

  final BackendFaceVerifier _backendVerifier;
  final double similarityThreshold;
  final double minFaceSizePx;
  final FaceDetector _faceDetector;

  Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  Future<List<CameraDescription>> frontCameras() async {
    final cameras = await availableCameras();
    final front = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.front)
        .toList();
    return front.isEmpty ? cameras : front;
  }

  Future<FaceVerificationResult> verifyCapture({
    required XFile image,
    required String context,
  }) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final faces = await _faceDetector.processImage(inputImage);
    final localResult = _validateFaces(faces);
    if (!localResult.isVerified) return localResult;

    // Integration point: this uses the existing backend saved face profile.
    // The live image is not stored locally after this call.
    return _backendVerifier(File(image.path), context);
  }

  FaceVerificationResult _validateFaces(List<Face> faces) {
    if (faces.isEmpty) {
      return FaceVerificationResult.failed(
        'No face detected. Please face the camera.',
      );
    }
    if (faces.length > 1) {
      return FaceVerificationResult.failed(
        'Multiple faces detected. Only one face is allowed.',
      );
    }

    final face = faces.first;
    if (face.boundingBox.width < minFaceSizePx ||
        face.boundingBox.height < minFaceSizePx) {
      return FaceVerificationResult.failed('Move closer to the camera.');
    }

    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    if (leftEye != null &&
        rightEye != null &&
        leftEye < 0.20 &&
        rightEye < 0.20) {
      return FaceVerificationResult.failed('Please keep your eyes open.');
    }

    return FaceVerificationResult.verified(
      message: 'Face detected.',
      similarity: similarityThreshold,
    );
  }

  Future<void> dispose() => _faceDetector.close();
}
