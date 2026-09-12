import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../core/constants/app_colors.dart';
import 'shimmer_loader.dart';
import 'youtube_search_frame.dart';

class AnimeTrailer extends StatefulWidget {
  const AnimeTrailer({
    super.key,
    required this.videoId,
    this.searchQuery,
    this.loading = false,
  });

  final String? videoId;
  final String? searchQuery;
  final bool loading;

  @override
  State<AnimeTrailer> createState() => _AnimeTrailerState();
}

class _AnimeTrailerState extends State<AnimeTrailer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _bind(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant AnimeTrailer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _bind(widget.videoId);
    }
  }

  void _bind(String? videoId) {
    _controller?.close();
    _controller = null;
    if (videoId == null || videoId.isEmpty) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        pointerEvents: PointerEvents.auto,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && _controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ShimmerLoader(height: 180, radius: 16),
      );
    }

    final controller = _controller;
    if (controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.black,
          child: YoutubePlayer(
            controller: controller,
            aspectRatio: 16 / 9,
            backgroundColor: Colors.black,
            enableFullScreenOnVerticalDrag: false,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
          ),
        ),
      );
    }

    final query = widget.searchQuery?.trim();
    if (query != null && query.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubeSearchFrame(query: query),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: const Text(
        'No official trailer is listed for this title.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
