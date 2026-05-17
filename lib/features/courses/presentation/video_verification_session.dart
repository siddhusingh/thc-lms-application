enum VideoVerificationState {
  unverified,
  verified,
  reverificationRequired,
  setupRequired,
}

class VideoVerificationSession {
  VideoVerificationState _state = VideoVerificationState.unverified;

  VideoVerificationState get state => _state;

  bool get canPlay => _state == VideoVerificationState.verified;

  void resetForLesson() {
    _state = VideoVerificationState.unverified;
  }

  void markVerified() {
    _state = VideoVerificationState.verified;
  }

  void requireReverification() {
    _state = VideoVerificationState.reverificationRequired;
  }

  void requireFaceSetup() {
    _state = VideoVerificationState.setupRequired;
  }

  bool canRunPeriodicCheck({
    required bool ready,
    required bool playing,
    required bool checkRunning,
  }) {
    return ready && playing && canPlay && !checkRunning;
  }
}
