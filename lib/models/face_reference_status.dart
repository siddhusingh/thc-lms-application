enum FaceReferencePhase { idle, preparing, ready, failed, missing }

class FaceReferenceStatus {
  const FaceReferenceStatus({required this.phase, this.message});

  const FaceReferenceStatus.idle() : this(phase: FaceReferencePhase.idle);

  const FaceReferenceStatus.preparing({
    String message = 'Preparing face verification...',
  }) : this(phase: FaceReferencePhase.preparing, message: message);

  const FaceReferenceStatus.ready()
    : this(
        phase: FaceReferencePhase.ready,
        message: 'Face verification is ready.',
      );

  const FaceReferenceStatus.failed(String message)
    : this(phase: FaceReferencePhase.failed, message: message);

  const FaceReferenceStatus.missing({
    String message =
        'Upload clear front, left, and right face images before watching course videos.',
  }) : this(phase: FaceReferencePhase.missing, message: message);

  final FaceReferencePhase phase;
  final String? message;

  bool get isReady => phase == FaceReferencePhase.ready;
  bool get isPreparing => phase == FaceReferencePhase.preparing;
  bool get isMissing => phase == FaceReferencePhase.missing;
}
