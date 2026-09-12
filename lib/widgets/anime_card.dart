import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/models/anime.dart';
import 'poster_image.dart';
import 'rating_badge.dart';

class AnimeCard extends StatelessWidget {
  const AnimeCard({
    super.key,
    required this.anime,
    required this.onTap,
    this.width = 132,
    this.progress,
  });

  final Anime anime;
  final VoidCallback onTap;
  final double width;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.gold.withValues(alpha: 0.16),
        highlightColor: AppColors.gold.withValues(alpha: 0.08),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: PosterImage(url: anime.poster, malId: anime.malId),
                    ),
                  ),
                  if (anime.score != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RatingBadge(score: anime.score!, compact: true),
                    ),
                  if (progress != null)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white24,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              anime.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class AnimePosterRow extends StatelessWidget {
  const AnimePosterRow({
    super.key,
    required this.items,
    required this.onTap,
    this.progressFor,
    this.leading,
  });

  final List<Anime> items;
  final ValueChanged<Anime> onTap;
  final double? Function(Anime anime)? progressFor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final extra = leading == null ? 0 : 1;
    if (items.isEmpty && leading == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'Nothing to show yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 236,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: items.length + extra,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (leading != null && index == 0) return leading!;
          final anime = items[index - extra];
          return AnimeCard(
            key: ValueKey('row-${anime.malId}'),
            anime: anime,
            onTap: () => onTap(anime),
            progress: progressFor?.call(anime),
          );
        },
      ),
    );
  }
}
