class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.hasMore,
  });

  final List<T> items;
  final int currentPage;
  final bool hasMore;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final rawItems = json['data'] ?? json['items'] ?? json['results'] ?? [];
    final items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().map(mapper).toList()
        : <T>[];
    final currentPage = _toInt(
      json['current_page'] ?? json['page'],
      fallback: 1,
    );
    final lastPage = _toInt(
      json['last_page'] ?? json['total_pages'],
      fallback: currentPage,
    );
    final hasMore = json['has_more'] == true || currentPage < lastPage;
    return PaginatedResponse(
      items: items,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }

  static int _toInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
