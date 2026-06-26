import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../app_state.dart';
import '../repositories/api_client.dart';

final _registered = <String>{};

/// For /video/stream/ URLs: append ?token=JWT so the browser video
/// element can authenticate (HTML video elements cannot set custom headers).
String _secureVideoUrl(String url) {
  final resolved = ApiClient.resolveUrl(url);
  final token = AppState.token;
  if (token == null) return resolved;
  final uri = Uri.parse(resolved);
  if (!uri.path.contains('/video/stream/')) return resolved;
  return uri
      .replace(queryParameters: {...uri.queryParameters, 'token': token})
      .toString();
}

Widget buildYouTubeEmbed(String videoId) {
  final viewType = 'yt-iframe-$videoId';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int id) => web.HTMLIFrameElement()
        ..src = 'https://www.youtube.com/embed/$videoId?rel=0'
        ..allow =
            'accelerometer; autoplay; clipboard-write; '
            'encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: HtmlElementView(viewType: viewType),
  );
}

Widget buildNetworkVideo(String url) {
  // Resolve auth token into the URL before registering; use the secured URL
  // as the cache key so re-logins with a new token still re-register.
  final securedUrl = _secureVideoUrl(url);
  final viewType = 'video-${securedUrl.hashCode}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
      final wrapper = web.HTMLDivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#0f172a';

      final message = web.HTMLDivElement()
        ..textContent =
            'Video could not be loaded. Check that the backend is running and the file format is browser playable.'
        ..style.display = 'none'
        ..style.position = 'absolute'
        ..style.left = '16px'
        ..style.right = '16px'
        ..style.top = '50%'
        ..style.transform = 'translateY(-50%)'
        ..style.color = '#ffffff'
        ..style.fontFamily = 'Inter, Arial, sans-serif'
        ..style.fontSize = '14px'
        ..style.lineHeight = '1.5'
        ..style.textAlign = 'center';

      final video = web.HTMLVideoElement()
        ..src = securedUrl
        ..controls = true
        ..preload = 'metadata'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.backgroundColor = '#0f172a';

      // Disable right-click context menu to remove the "Save video as" option.
      video.onContextMenu.listen((e) => e.preventDefault());

      video.onError.listen((_) {
        message.style.display = 'block';
      });

      wrapper.append(video);
      wrapper.append(message);
      return wrapper;
    });
  }
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: HtmlElementView(viewType: viewType),
  );
}

Widget buildDocumentEmbed(String url) {
  final viewType = 'doc-${url.hashCode}';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
      // <embed> is more reliable than <iframe> for PDFs in Chrome — it uses
      // Chrome's built-in PDF viewer directly without triggering iframe CSP
      // restrictions.
      final embed = web.HTMLEmbedElement()
        ..src = url
        ..type = 'application/pdf'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      // Fallback wrapper: if the browser can't render the PDF inline it will
      // show the inner content instead.
      final fallback = web.HTMLDivElement()
        ..style.display = 'flex'
        ..style.flexDirection = 'column'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.height = '100%'
        ..style.fontFamily = 'Inter, Arial, sans-serif'
        ..style.color = '#6F7E8D'
        ..style.fontSize = '14px';

      final link = web.HTMLAnchorElement()
        ..href = url
        ..target = '_blank'
        ..textContent = 'Open PDF in new tab';
      link.style.color = '#216DF4';

      fallback
        ..append(web.HTMLParagraphElement()..textContent = 'PDF preview not available.')
        ..append(link);

      final container = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#f8f9fa';
      container
        ..append(embed)
        ..append(fallback);
      return container;
    });
  }
  return SizedBox(height: 560, child: HtmlElementView(viewType: viewType));
}
