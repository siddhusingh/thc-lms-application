class FaceVerificationResult {
  const FaceVerificationResult({
    required this.isVerified,
    required this.message,
    this.similarity,
  });

  final bool isVerified;
  final String message;
  final double? similarity;

  factory FaceVerificationResult.verified({
    String message = 'Face verified.',
    double? similarity,
  }) {
    return FaceVerificationResult(
      isVerified: true,
      message: message,
      similarity: similarity,
    );
  }

  factory FaceVerificationResult.failed(String message, {double? similarity}) {
    return FaceVerificationResult(
      isVerified: false,
      message: message,
      similarity: similarity,
    );
  }
}
