import 'package:web/web.dart' as web;

Future<bool> downloadFile(String url, String fileName) async {
  final downloadUrl = _withDownloadMode(url, fileName);
  final anchor = web.HTMLAnchorElement()
    ..href = downloadUrl
    ..download = fileName
    ..target = '_self';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

String _withDownloadMode(String url, String fileName) {
  final parsed = Uri.tryParse(url);
  if (parsed == null) return url;
  if (parsed.pathSegments.isEmpty || parsed.pathSegments.first != 'uploads') {
    return url;
  }
  return parsed
      .replace(
        queryParameters: {
          ...parsed.queryParameters,
          'download': '1',
          'filename': fileName,
        },
      )
      .toString();
}
