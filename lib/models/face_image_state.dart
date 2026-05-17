enum FaceImageSlot { front, left, right }

extension FaceImageSlotX on FaceImageSlot {
  String get apiValue => name;

  String get label => switch (this) {
    FaceImageSlot.front => 'Front',
    FaceImageSlot.left => 'Left',
    FaceImageSlot.right => 'Right',
  };
}

class FaceImageState {
  const FaceImageState({
    required this.front,
    required this.left,
    required this.right,
    required this.isComplete,
  });

  final String? front;
  final String? left;
  final String? right;
  final bool isComplete;

  factory FaceImageState.fromJson(Map<String, dynamic> json) {
    final front = _normalizedUrl(json['front']);
    final left = _normalizedUrl(json['left']);
    final right = _normalizedUrl(json['right']);

    return FaceImageState(
      front: front,
      left: left,
      right: right,
      isComplete: json.containsKey('is_complete')
          ? json['is_complete'] == true
          : front != null && left != null && right != null,
    );
  }

  bool get hasMissingImages => front == null || left == null || right == null;

  String? imageFor(FaceImageSlot slot) => switch (slot) {
    FaceImageSlot.front => front,
    FaceImageSlot.left => left,
    FaceImageSlot.right => right,
  };

  static String? _normalizedUrl(Object? value) {
    final url = value?.toString().trim();
    return url == null || url.isEmpty ? null : url;
  }
}
