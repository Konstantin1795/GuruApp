class ApiMeta {
  final String? requestId;

  const ApiMeta({required this.requestId});

  factory ApiMeta.fromJson(Map<String, dynamic> json) =>
      ApiMeta(requestId: json['request_id'] as String?);
}

class ApiError {
  final String message;
  final String type;
  final Map<String, dynamic>? fields;
  final String? requestId;

  const ApiError({
    required this.message,
    required this.type,
    required this.fields,
    required this.requestId,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        message: (json['message'] as String?) ?? 'Unknown error',
        type: (json['type'] as String?) ?? 'Unknown',
        fields: (json['fields'] as Map?)?.cast<String, dynamic>(),
        requestId: (json['meta'] as Map?)?['request_id'] as String?,
      );
}

class ApiResponse<T> {
  final bool ok;
  final T data;
  final ApiMeta meta;

  const ApiResponse({
    required this.ok,
    required this.data,
    required this.meta,
  });

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic>) parseData,
  }) {
    return ApiResponse<T>(
      ok: json['ok'] == true,
      data: parseData((json['data'] as Map).cast<String, dynamic>()),
      meta: ApiMeta.fromJson((json['meta'] as Map).cast<String, dynamic>()),
    );
  }
}

class PaginationInfo {
  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  const PaginationInfo({
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => PaginationInfo(
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        total: json['total'] as int,
        lastPage: json['last_page'] as int,
      );

  bool get hasMore => page < lastPage;
}

class Paginated<T> {
  final List<T> items;
  final PaginationInfo pagination;

  const Paginated({
    required this.items,
    required this.pagination,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic>) parseItem,
  }) {
    final itemsRaw = (json['items'] as List).cast<Map>();
    return Paginated<T>(
      items: itemsRaw.map((e) => parseItem(e.cast<String, dynamic>())).toList(growable: false),
      pagination: PaginationInfo.fromJson((json['pagination'] as Map).cast<String, dynamic>()),
    );
  }
}

