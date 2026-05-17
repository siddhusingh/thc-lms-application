import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/face_reference_status.dart';

void main() {
  test('face reference readiness helpers reflect the active phase', () {
    expect(const FaceReferenceStatus.idle().isReady, isFalse);
    expect(const FaceReferenceStatus.preparing().isPreparing, isTrue);
    expect(const FaceReferenceStatus.ready().isReady, isTrue);
    expect(const FaceReferenceStatus.missing().isMissing, isTrue);
    expect(
      const FaceReferenceStatus.failed('failed').phase,
      FaceReferencePhase.failed,
    );
  });
}
