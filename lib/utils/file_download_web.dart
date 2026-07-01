import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../app_state.dart';

/// Downloads a file by fetching bytes through the authenticated HTTP client,
/// then serving them as a same-origin blob URL.
///
/// This avoids the Chrome "insecure download" warning that occurs when an
/// anchor element points directly to an HTTP backend URL (e.g. http://192.168.x.x:8000).
/// By converting the response into a blob:// URL, the browser sees a
/// same-origin secure resource and downloads without warnings.
Future<bool> downloadFile(String url, String fileName) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Fetch through the same authenticated channel used for all API calls
    final response = await http.get(
      uri,
      headers: {
        if (AppState.token != null)
          'Authorization': 'Bearer ${AppState.token}',
        'Accept': 'application/pdf, application/octet-stream, */*',
      },
    );

    if (response.statusCode != 200) {
      // Fall back to direct anchor if the fetch failed
      return _directAnchor(_withDownloadMode(url, fileName), fileName);
    }

    // Build a blob URL from the bytes — this is always same-origin/secure
    final bytes = response.bodyBytes;
    final jsArray = bytes.buffer.toJS;
    final blob = web.Blob(
      [jsArray].toJS,
      web.BlobPropertyBag(type: _mimeFor(fileName)),
    );
    final blobUrl = web.URL.createObjectURL(blob);

    _triggerAnchor(blobUrl, fileName);
    web.URL.revokeObjectURL(blobUrl);
    return true;
  } catch (_) {
    // Last resort: fall through to direct link
    return _directAnchor(_withDownloadMode(url, fileName), fileName);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

bool _directAnchor(String url, String fileName) {
  _triggerAnchor(url, fileName);
  return true;
}

void _triggerAnchor(String href, String fileName) {
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

String _mimeFor(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  return switch (ext) {
    'pdf'  => 'application/pdf',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'zip'  => 'application/zip',
    'png'  => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _      => 'application/octet-stream',
  };
}

String _withDownloadMode(String url, String fileName) {
  final parsed = Uri.tryParse(url);
  if (parsed == null) return url;
  if (parsed.pathSegments.isEmpty ||
      parsed.pathSegments.first != 'uploads') {
    return url;
  }
  return parsed.replace(queryParameters: {
    ...parsed.queryParameters,
    'download': '1',
    'filename': fileName,
  }).toString();
}
