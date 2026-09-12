import 'package:flutter/widgets.dart';

import 'youtube_search_frame_stub.dart'
    if (dart.library.html) 'youtube_search_frame_web.dart'
    if (dart.library.io) 'youtube_search_frame_io.dart' as impl;

class YoutubeSearchFrame extends StatelessWidget {
  const YoutubeSearchFrame({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return impl.buildYoutubeSearchFrame(query);
  }
}
