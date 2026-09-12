import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/anime.dart';
import '../../data/services/remote_config_service.dart';
import '../../state/watchlist_provider.dart';
import '../../widgets/anime_card.dart';
import '../details/anime_details_view.dart';

class WatchlistView extends StatelessWidget {
  const WatchlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistProvider>();
    final showAds = context.read<RemoteConfigService>().showAds;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Saved', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: showAds
                ? _AnimeGrid(
                    items: watchlist.bookmarks,
                    empty: 'Bookmark titles from the details screen to build your list.',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AnimeGrid extends StatelessWidget {
  const _AnimeGrid({required this.items, required this.empty});

  final List<Anime> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(empty, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
          key: ValueKey('saved-${anime.malId}'),
          width: double.infinity,
          anime: anime,
          onTap: () => AnimeDetailsView.open(context, anime),
        );
      },
    );
  }
}
