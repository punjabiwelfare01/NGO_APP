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
