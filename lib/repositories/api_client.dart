import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_state.dart';
import '../core/config.dart';
import '../utils/logger.dart';

class ApiClient {
  const ApiClient._();

  static String get baseUrl => AppConfig.apiBaseUrl;

  // Getter so the Authorization header is included dynamically after login.
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Required for API calls through free ngrok tunnels. Harmless elsewhere.
    'ngrok-skip-browser-warning': 'true',
    if (AppState.token != null) 'Authorization': 'Bearer ${AppState.token}',
  };

  static Future<dynamic> get(String path) async {
    AppLogger.request('GET', path);
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(AppConfig.apiTimeout);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    AppLogger.request('POST', path);
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(AppConfig.apiTimeout);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    AppLogger.request('PUT', path);
    final res = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(AppConfig.apiTimeout);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    AppLogger.request('PATCH', path);
    final res = await http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(AppConfig.apiTimeout);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  static Future<void> delete(String path) async {
    AppLogger.request('DELETE', path);
    final res = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(AppConfig.apiTimeout);
    AppLogger.response(res.statusCode, path);
    _check(res);
  }

  static Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<int> fileBytes,
    required String fileName,
    String fileField = 'file',
  }) async {
    AppLogger.request('POST (multipart)', path);
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }
    request.headers['Accept'] = 'application/json';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
    );
    final streamed = await request.send().timeout(AppConfig.apiTimeout);
    final res = await http.Response.fromStream(streamed);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  static void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      AppLogger.error(
        'API error ${res.statusCode}',
        tag: 'HTTP',
        error: res.body,
      );
      throw ApiException(res.statusCode, res.body);
    }
  }

  static dynamic _decodeJson(http.Response res, String path) {
    try {
      return jsonDecode(res.body);
    } on FormatException catch (e) {
      final contentType = res.headers['content-type'] ?? 'unknown';
      final preview = res.body.length > 160
          ? '${res.body.substring(0, 160)}...'
          : res.body;
      AppLogger.error(
        'Invalid JSON from $path',
        tag: 'HTTP',
        error: 'content-type=$contentType body=$preview',
      );
      throw ApiException(
        res.statusCode,
        'Invalid JSON from API. $contentType. ${e.message}',
      );
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
