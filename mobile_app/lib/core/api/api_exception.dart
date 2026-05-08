class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? requestId;
  final String? type;
  final Map<String, dynamic>? fields;

  const ApiException({
    required this.statusCode,
    required this.message,
    required this.requestId,
    required this.type,
    required this.fields,
  });

  @override
  String toString() =>
      'ApiException(statusCode=$statusCode, message=$message, requestId=$requestId, type=$type)';
}

