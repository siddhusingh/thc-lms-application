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
          ? _toBool(json['is_complete'])
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
    if (value is Map<String, dynamic>) {
      return _normalizedUrl(
        value['url'] ??
            value['image_url'] ??
            value['file_url'] ??
            value['path'] ??
            value['image'] ??
            value['file'],
      );
    }
    final url = value?.toString().trim();
    return url == null || url.isEmpty ? null : url;
  }

  static bool _toBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
