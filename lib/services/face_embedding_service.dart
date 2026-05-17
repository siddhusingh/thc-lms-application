import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingService {
  FaceEmbeddingService({this.modelAssetPath, this.embeddingThreshold = 0.75});

  final String? modelAssetPath;
  final double embeddingThreshold;
  Interpreter? _interpreter;

  bool get isReady => _interpreter != null;

  Future<void> initialize() async {
    final assetPath = modelAssetPath;
    if (assetPath == null || assetPath.isEmpty || _interpreter != null) {
      return;
    }
    _interpreter = await Interpreter.fromAsset(assetPath);
  }

  // Integration point: once a MobileFaceNet/FaceNet model asset is added,
  // preprocess the cropped face image here and run the model to return an
  // embedding. This is intentionally isolated from the video player.
  Future<List<double>?> generateEmbedding(Uint8List faceBytes) async {
    if (_interpreter == null) return null;
    throw UnimplementedError(
      'Add MobileFaceNet preprocessing for $modelAssetPath here.',
    );
  }

  double cosineSimilarity(List<double> first, List<double> second) {
    if (first.isEmpty || first.length != second.length) return 0;
    var dot = 0.0;
    var firstNorm = 0.0;
    var secondNorm = 0.0;
    for (var i = 0; i < first.length; i++) {
      dot += first[i] * second[i];
      firstNorm += first[i] * first[i];
      secondNorm += second[i] * second[i];
    }
    final denominator = math.sqrt(firstNorm) * math.sqrt(secondNorm);
    if (denominator == 0) return 0;
    return dot / denominator;
  }

  bool isMatch(List<double> liveEmbedding, List<double> savedEmbedding) {
    return cosineSimilarity(liveEmbedding, savedEmbedding) >=
        embeddingThreshold;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
