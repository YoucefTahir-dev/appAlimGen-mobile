class PageData<T> {
  const PageData({
    required this.items,
    required this.count,
    required this.hasNext,
  });
  final List<T> items;
  final int count;
  final bool hasNext;

  factory PageData.fromApi(
    dynamic value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value is! Map) {
      throw const FormatException('Page API invalide.');
    }
    final rawResults = value['results'];
    if (rawResults is! List) {
      throw const FormatException('Résultats paginés invalides.');
    }
    return PageData(
      items: rawResults
          .map((item) => decode(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      count: (value['count'] as num?)?.toInt() ?? rawResults.length,
      hasNext: value['next'] != null,
    );
  }
}

class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.query = '',
    this.page = 0,
    this.hasNext = false,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.error,
  });
  final List<T> items;
  final String query;
  final int page;
  final bool hasNext;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final Object? error;

  PagedListState<T> copyWith({
    List<T>? items,
    String? query,
    int? page,
    bool? hasNext,
    bool? isInitialLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) => PagedListState<T>(
    items: items ?? this.items,
    query: query ?? this.query,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: clearError ? null : error ?? this.error,
  );
}
