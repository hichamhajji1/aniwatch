import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../data/models/anime.dart';
import '../../widgets/anime_card.dart';
import '../details/anime_details_view.dart';

class SeeAllView extends StatelessWidget {
  const SeeAllView({super.key, required this.title, required this.items, this.onOpen});

  final String title;
  final List<Anime> items;
  final ValueChanged<Anime>? onOpen;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required List<Anime> items,
    ValueChanged<Anime>? onOpen,
  }) {
    return Navigator.of(context).push(
      AniPageRoute(builder: (_) => SeeAllView(title: title, items: items, onOpen: onOpen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.52,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final anime = items[index];
          return AnimeCard(
            key: ValueKey('see-all-${anime.malId}'),
            width: double.infinity,
            anime: anime,
            onTap: () {
              final open = onOpen;
              if (open != null) {
                open(anime);
              } else {
                AnimeDetailsView.open(context, anime);
              }
            },
          );
        },
      ),
    );
  }
}
