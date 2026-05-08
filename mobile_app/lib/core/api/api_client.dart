import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Logger _logger;

  ApiClient({
    required TokenStorage tokenStorage,
    String? baseUrl,
    Logger? logger,
  })  : _tokenStorage = tokenStorage,
        _logger = logger ?? Logger(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? AppConfig.defaultBaseUrl,
            connectTimeout: AppConfig.requestTimeout,
            sendTimeout: AppConfig.requestTimeout,
            receiveTimeout: AppConfig.requestTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    _logger.i('GURU API baseUrl: ${_dio.options.baseUrl}');

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.i('${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          final requestId = response.headers.value('x-request-id');
          if (requestId != null) {
            _logger.d('request_id=$requestId');
          }
          handler.next(response);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    try {
      final res = await _dio.post(path, data: body);
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) return (jsonDecode(data) as Map).cast<String, dynamic>();
    if (data is Map) return data.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final headers = e.response?.headers;
    final requestId = headers?.value('x-request-id');
    final data = _asJsonMap(e.response?.data);
    final error = (data['error'] as Map?)?.cast<String, dynamic>();
    final meta = (data['meta'] as Map?)?.cast<String, dynamic>();
    return ApiException(
      statusCode: status,
      message: (error?['message'] as String?) ?? e.message ?? 'Request failed',
      requestId: (meta?['request_id'] as String?) ?? requestId,
      type: (error?['type'] as String?),
      fields: (error?['fields'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

