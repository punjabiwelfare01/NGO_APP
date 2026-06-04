import 'package:web/web.dart' as web;

Future<bool> downloadFile(String url, String fileName) async {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..target = '_self';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
