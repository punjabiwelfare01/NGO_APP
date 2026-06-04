import 'package:url_launcher/url_launcher.dart';

Future<bool> downloadFile(String url, String fileName) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  return launchUrl(uri);
}
