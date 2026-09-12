import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/anime.dart';
import '../../data/services/remote_config_service.dart';
import '../../state/catalog_provider.dart';
import '../../state/reminder_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/jump_search_field.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loader.dart';
import '../details/anime_details_view.dart';
import 'see_all_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, this.onOpenSearch});

  final ValueChanged<String>? onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final name = context.watch<ReminderProvider>().displayName;
    final greeting = name.isEmpty ? 'Hello there!' : 'Hello $name!';
    final showAds = context.read<RemoteConfigService>().showAds;

    final header = SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AniWordmark(size: 30),
              const SizedBox(height: 18),
              Text(
                '$greeting 😄',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              JumpSearchField(
                onSearch: (query) => onOpenSearch?.call(query),
              ),
            ],
          ),
        ),
      ),
    );

    if (!showAds) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [header],
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surfaceHigh,
      onRefresh: catalog.loadHome,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          header,
          if (catalog.loadingHome && catalog.topAnime.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 24),
                child: PosterShimmerRow(),
              ),
            )
          else ...[
            if (catalog.hero != null)
              SliverToBoxAdapter(
                child: HeroBanner(featured: catalog.hero!, trail: catalog.topAnime),
              ),
            ..._rail(context, 'Top Anime', catalog.topAnime),
            ..._rail(context, 'Currently Airing Season', catalog.seasonalAnime),
            ..._rail(context, 'Most Popular', catalog.popularAnime),
            ..._rail(context, 'Upcoming', catalog.upcomingAnime),
            ..._rail(context, 'Highest Rated', catalog.highestRated),
            ..._rail(context, 'Movies', catalog.movies),
            ..._rail(context, 'TV Series', catalog.tvSeries),
            ..._rail(context, 'Action', catalog.withGenre('Action')),
            ..._rail(context, 'Fantasy', catalog.withGenre('Fantasy')),
            ..._rail(context, 'Romance', catalog.withGenre('Romance')),
            ..._rail(context, 'OVA', catalog.ovas),
            ..._rail(context, 'ONA', catalog.onas),
            ..._rail(context, 'Specials', catalog.specials),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ],
      ),
    );
  }

  List<Widget> _rail(BuildContext context, String title, List<Anime> items) {
    if (items.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: title,
          onSeeAll: () => SeeAllView.open(context, title: title, items: items),
        ),
      ),
      SliverToBoxAdapter(
        child: AnimePosterRow(
          items: items,
          onTap: (anime) => AnimeDetailsView.open(context, anime),
        ),
      ),
    ];
  }
}
