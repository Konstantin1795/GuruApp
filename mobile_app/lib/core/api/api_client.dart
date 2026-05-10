import 'dart:convert';
import 'dart:typed_data';

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
            // Важно: при Content-Type: application/json Dio по умолчанию парсит тело как JSON.
            // Если сервер/прокси отдал HTML, внутри Dio падает с «syntax error … "<"» до нашего кода.
            responseType: ResponseType.plain,
            followRedirects: false,
            headers: const {
              Headers.acceptHeader: Headers.jsonContentType,
            },
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
      return _decodeResponseBody(res.data, statusCode: res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return _decodeResponseBody(res.data, statusCode: res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? body}) async {
    try {
      final res = await _dio.patch(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return _decodeResponseBody(res.data, statusCode: res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    try {
      final res = await _dio.delete(path);
      return _decodeResponseBody(res.data, statusCode: res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Parses API JSON object; on failure throws [ApiException] with a readable message (not raw FormatException).
  Map<String, dynamic> _decodeResponseBody(dynamic data, {int? statusCode}) {
    if (data is String && _looksLikeHtml(data)) {
      throw ApiException(
        statusCode: statusCode,
        message:
            'Сервер ответил HTML-страницей вместо JSON. Частые причины: неверный адрес API (нужен суффикс /api), сеть Android блокирует HTTP (нужен usesCleartextTraffic), backend не запущен или вы не в company workspace.',
        requestId: null,
        type: 'HtmlResponse',
        fields: null,
      );
    }
    try {
      return _asJsonMap(data);
    } on FormatException catch (e) {
      final preview = _rawBodyPreview(data);
      throw ApiException(
        statusCode: statusCode,
        message: preview.isNotEmpty
            ? 'Ответ сервера не JSON. Начало ответа: $preview'
            : 'Ответ сервера не JSON (${e.message})',
        requestId: null,
        type: null,
        fields: null,
      );
    }
  }

  bool _looksLikeHtml(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    final lower = s.length > 64 ? s.substring(0, 64).toLowerCase() : s.toLowerCase();
    return s.startsWith('<') ||
        lower.startsWith('<!doctype') ||
        lower.startsWith('<html') ||
        lower.startsWith('<head') ||
        lower.startsWith('<body');
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data == null) return <String, dynamic>{};
    // responseType.plain обычно даёт String; на всякий случай — Map и UTF-8 bytes.
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List<int>) {
      return _asJsonMap(utf8.decode(data, allowMalformed: true));
    }
    if (data is Uint8List) {
      return _asJsonMap(utf8.decode(data, allowMalformed: true));
    }
    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw FormatException('JSON root must be an object');
    }
    throw FormatException('Unsupported response type ${data.runtimeType}');
  }

  String _rawBodyPreview(dynamic raw, [int maxLen = 400]) {
    if (raw == null) return '';
    if (raw is String) {
      final t = raw.trim();
      return t.length > maxLen ? '${t.substring(0, maxLen)}…' : t;
    }
    return raw.toString();
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final headers = e.response?.headers;
    final requestId = headers?.value('x-request-id');
    Map<String, dynamic> data;
    try {
      data = _asJsonMap(e.response?.data);
    } catch (_) {
      final preview = _rawBodyPreview(e.response?.data);
      return ApiException(
        statusCode: status,
        message: preview.isNotEmpty ? preview : (e.message ?? 'Request failed'),
        requestId: requestId,
        type: null,
        fields: null,
      );
    }
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

