import 'dart:convert';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../app_state.dart';
import '../core/config.dart';
import '../utils/logger.dart';

/// Best-effort MIME type lookup from a filename, falling back to a generic
/// binary type when the extension is unrecognized (e.g. no extension).
/// Servers that whitelist specific content types (PDF/JPEG/PNG uploads)
/// need this — without it, `http.MultipartFile` defaults to
/// `application/octet-stream`, which such whitelists reject outright.
MediaType _mediaTypeFor(String fileName) {
  final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
  return MediaType.parse(mimeType);
}

class ApiClient {
  const ApiClient._();

  static String get baseUrl => AppConfig.apiBaseUrl;

  static String resolveUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) return '$baseUrl$trimmed';
    return '$baseUrl/$trimmed';
  }

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
    Duration? timeout,
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
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: _mediaTypeFor(fileName),
      ),
    );
    final streamed = await request.send().timeout(timeout ?? AppConfig.apiTimeout);
    final res = await http.Response.fromStream(streamed);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  /// Upload a file by path (streams from disk — does NOT load the whole file into
  /// memory). Use this instead of [postMultipart] for large files on non-web
  /// platforms where a file path is available.
  static Future<dynamic> postMultipartFromPath(
    String path, {
    required Map<String, String> fields,
    required String filePath,
    required String fileName,
    String fileField = 'file',
    Duration? timeout,
  }) async {
    AppLogger.request('POST (multipart/path)', path);
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (AppState.token != null) {
      request.headers['Authorization'] = 'Bearer ${AppState.token}';
    }
    request.headers['Accept'] = 'application/json';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    request.fields.addAll(fields);
    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        filePath,
        filename: fileName,
        contentType: _mediaTypeFor(fileName),
      ),
    );
    final streamed = await request.send().timeout(timeout ?? AppConfig.apiTimeout);
    final res = await http.Response.fromStream(streamed);
    AppLogger.response(res.statusCode, path);
    _check(res);
    return _decodeJson(res, path);
  }

  /// Upload a file using dio with real send-progress callbacks.
  ///
  /// Pass either [filePath] OR ([fileStream] + [fileStreamSize]):
  /// - [filePath]: lazy file open (may fail if Android deletes the cache file
  ///   between pick and upload — use as fallback / retry only).
  /// - [fileStream] + [fileStreamSize]: immediately-opened stream from
  ///   `file_picker`'s `withReadStream: true`; the file descriptor stays alive
  ///   even if Android cleans the cache, making it safe for large files.
  static Future<dynamic> uploadFileWithProgress(
    String path, {
    String? filePath,
    Stream<List<int>>? fileStream,
    int? fileStreamSize,
    required String fileName,
    Map<String, String> fields = const {},
    String fileField = 'file',
    Duration? timeout,
    void Function(int sent, int total)? onProgress,
  }) async {
    assert(
      filePath != null || (fileStream != null && fileStreamSize != null),
      'Provide filePath OR fileStream+fileStreamSize',
    );
    AppLogger.request('POST (dio/multipart)', path);

    final effectiveTimeout = timeout ?? AppConfig.videoUploadTimeout;
    final client = dio_pkg.Dio(
      dio_pkg.BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: effectiveTimeout,
        sendTimeout: effectiveTimeout,
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (AppState.token != null) 'Authorization': 'Bearer ${AppState.token}',
        },
      ),
    );

    // Prefer the already-open stream; fall back to opening from path.
    final dio_pkg.MultipartFile multipartFile;
    if (fileStream != null && fileStreamSize != null) {
      multipartFile = dio_pkg.MultipartFile.fromStream(
        () => fileStream,
        fileStreamSize,
        filename: fileName,
      );
    } else {
      multipartFile = await dio_pkg.MultipartFile.fromFile(
        filePath!,
        filename: fileName,
      );
    }

    final formData = dio_pkg.FormData.fromMap({
      ...fields,
      fileField: multipartFile,
    });

    final response = await client.post<Map<String, dynamic>>(
      path,
      data: formData,
      onSendProgress: onProgress,
    );

    AppLogger.response(response.statusCode ?? 0, path);
    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      throw ApiException(
        response.statusCode ?? 0,
        response.data?.toString() ?? 'Unknown error',
      );
    }
    return response.data;
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
