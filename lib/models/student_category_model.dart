class StudentCategoryModel {
  const StudentCategoryModel({required this.id, required this.name});

  final String id;
  final String name;

  String get displayName => name.isEmpty ? 'Category' : name;

  factory StudentCategoryModel.fromJson(Map<String, dynamic> json) {
    return StudentCategoryModel(
      id: _stringValue(json['id'] ?? json['category_id'] ?? json['value']),
      name: _stringValue(
        json['name'] ??
            json['title'] ??
            json['category'] ??
            json['category_name'] ??
            json['label'],
      ),
    );
  }
}

List<StudentCategoryModel> parseStudentCategories(Map<String, dynamic> json) {
  final payload = json['data'];
  final rawItems = payload is List
      ? payload
      : payload is Map<String, dynamic>
      ? (payload['categories'] ?? payload['items'] ?? payload['data'])
      : (json['categories'] ?? json['items'] ?? json['results']);
  final items = rawItems is List ? rawItems : const [];
  return items
      .whereType<Map<String, dynamic>>()
      .map(StudentCategoryModel.fromJson)
      .where((category) => category.id.isNotEmpty || category.name.isNotEmpty)
      .toList();
}

String _stringValue(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text;
}
