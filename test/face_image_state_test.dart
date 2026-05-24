import 'package:flutter_test/flutter_test.dart';
import 'package:thc_lms_mobile/models/face_image_state.dart';

void main() {
  test('parses nested face image urls from legacy response shapes', () {
    final state = FaceImageState.fromJson({
      'front': {'url': 'https://example.test/front.jpg'},
      'left': {'image_url': 'https://example.test/left.jpg'},
      'right': {'path': '/uploads/right.jpg'},
      'is_complete': 1,
    });

    expect(state.front, 'https://example.test/front.jpg');
    expect(state.left, 'https://example.test/left.jpg');
    expect(state.right, '/uploads/right.jpg');
    expect(state.isComplete, isTrue);
  });

  test('falls back to image presence when is_complete is absent', () {
    final state = FaceImageState.fromJson({
      'front': 'front.jpg',
      'left': 'left.jpg',
      'right': 'right.jpg',
    });

    expect(state.isComplete, isTrue);
  });
}
