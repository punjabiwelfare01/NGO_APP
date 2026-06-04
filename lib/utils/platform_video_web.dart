import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

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
  final viewType = 'video-${url.hashCode}';
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
        ..src = url
        ..controls = true
        ..preload = 'metadata'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.backgroundColor = '#0f172a';

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
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int id) => web.HTMLIFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }
  return SizedBox(height: 520, child: HtmlElementView(viewType: viewType));
}
