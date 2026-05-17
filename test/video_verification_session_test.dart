import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/features/courses/presentation/video_verification_session.dart';

void main() {
  test('lesson verification state transitions stay explicit', () {
    final session = VideoVerificationSession();

    expect(session.state, VideoVerificationState.unverified);
    expect(session.canPlay, isFalse);

    session.markVerified();
    expect(session.state, VideoVerificationState.verified);
    expect(session.canPlay, isTrue);

    session.requireReverification();
    expect(session.state, VideoVerificationState.reverificationRequired);
    expect(session.canPlay, isFalse);

    session.requireFaceSetup();
    expect(session.state, VideoVerificationState.setupRequired);
    expect(session.canPlay, isFalse);

    session.resetForLesson();
    expect(session.state, VideoVerificationState.unverified);
    expect(session.canPlay, isFalse);
  });

  test('periodic checks run only while verified playback is active', () {
    final session = VideoVerificationSession()..markVerified();

    expect(
      session.canRunPeriodicCheck(
        ready: true,
        playing: true,
        checkRunning: false,
      ),
      isTrue,
    );
    expect(
      session.canRunPeriodicCheck(
        ready: true,
        playing: false,
        checkRunning: false,
      ),
      isFalse,
    );
    expect(
      session.canRunPeriodicCheck(
        ready: true,
        playing: true,
        checkRunning: true,
      ),
      isFalse,
    );

    session.requireReverification();
    expect(
      session.canRunPeriodicCheck(
        ready: true,
        playing: true,
        checkRunning: false,
      ),
      isFalse,
    );
  });
}
