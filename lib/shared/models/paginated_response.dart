class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => page * pageSize < total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = (json['data'] as List<dynamic>? ?? []);
    return PaginatedResponse<T>(
      items: rawItems.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? rawItems.length,
      total: json['total'] as int? ?? rawItems.length,
    );
  }
}
