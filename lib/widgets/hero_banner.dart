import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/motion/ani_motion.dart';
import '../data/models/anime.dart';
import '../views/details/anime_details_view.dart';
import 'poster_image.dart';
import 'rating_badge.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key, required this.featured, this.trail = const [], this.onOpen});

  final Anime featured;
  final List<Anime> trail;
  final ValueChanged<Anime>? onOpen;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  List<Anime> get _items {
    final seen = <int>{};
    final items = <Anime>[];
    for (final anime in [widget.featured, ...widget.trail]) {
      if (anime.poster.isEmpty) continue;
      if (seen.add(anime.malId)) items.add(anime);
      if (items.length == 5) break;
    }
    if (items.isEmpty) {
      for (final anime in [widget.featured, ...widget.trail]) {
        if (seen.add(anime.malId)) items.add(anime);
        if (items.length == 5) break;
      }
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final items = _items;
    if (_index >= items.length) {
      _index = 0;
      if (_controller.hasClients && items.isNotEmpty) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final items = _items;
      if (items.length < 2) return;
      final next = (_index + 1) % items.length;
      _controller.animateToPage(
        next,
        duration: AniMotion.page,
        curve: AniMotion.curve,
      );
    });
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();
    final safeIndex = _index.clamp(0, items.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: items.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final anime = items[index];
                  return GestureDetector(
                    key: ValueKey('hero-${anime.malId}'),
                    onTap: () {
                      final open = widget.onOpen;
                      if (open != null) {
                        open(anime);
                      } else {
                        AnimeDetailsView.open(context, anime);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PosterImage(url: anime.poster, malId: anime.malId),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x33000000), Color(0xEE0A0A0A)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 72,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (anime.score != null) RatingBadge(score: anime.score!),
                              const SizedBox(height: 8),
                              Text(
                                anime.displayTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                anime.metaLine,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      GestureDetector(
                        onTap: () => _goTo(i),
                        child: Container(
                          width: i == safeIndex ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: i == safeIndex ? AppColors.gold : Colors.white38,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
