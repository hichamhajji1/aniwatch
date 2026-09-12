import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/anime.dart';
import '../../data/models/journal_shelf.dart';
import '../../state/journal_provider.dart';
import '../../state/reminder_provider.dart';
import '../../widgets/add_poster_card.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/jump_search_field.dart';
import '../../widgets/section_header.dart';
import '../home/see_all_view.dart';
import 'add_category_view.dart';
import 'add_entry_sheet.dart';
import 'journal_details_view.dart';

class JournalHomeView extends StatelessWidget {
  const JournalHomeView({super.key, this.onOpenExplore});

  final ValueChanged<String>? onOpenExplore;

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final name = context.watch<ReminderProvider>().displayName;
    final greeting = name.isEmpty ? 'Hello there!' : 'Hello $name!';
    final featured = journal.featuredEntry?.toAnime();
    final trail = journal.entries.map((item) => item.toAnime()).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AniWordmark(size: 30),
                      const Spacer(),
                      IconButton(
                        onPressed: () => AddEntrySheet.show(context, shelf: JournalShelf.top),
                        icon: const Icon(Icons.add_rounded, color: AppColors.gold),
                        tooltip: 'Add a title',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$greeting 😄',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  JumpSearchField(
                    onSearch: (query) => onOpenExplore?.call(query),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (featured == null)
          SliverToBoxAdapter(
            child: EmptyHeroAdd(
              onTap: () => AddEntrySheet.show(context, shelf: JournalShelf.top),
            ),
          )
        else
          SliverToBoxAdapter(
            child: HeroBanner(
              featured: featured,
              trail: trail,
              onOpen: (anime) => JournalDetailsView.openFromAnime(context, anime),
            ),
          ),
        for (final shelf in journal.homeShelves)
          ..._shelfRail(
            context,
            title: shelf.title,
            items: journal.animeByShelf(shelf.id),
            onAdd: () => AddEntrySheet.show(context, shelf: shelf, kind: shelf.kind),
          ),
        if (journal.availableShelves.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextButton.icon(
                onPressed: () => AddCategoryView.open(context),
                icon: const Icon(Icons.add_rounded, color: AppColors.gold),
                label: const Text(
                  'Add a category',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  List<Widget> _shelfRail(
    BuildContext context, {
    required String title,
    required List<Anime> items,
    required VoidCallback onAdd,
  }) {
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: title,
          onSeeAll: items.isEmpty
              ? null
              : () => SeeAllView.open(
                    context,
                    title: title,
                    items: items,
                    onOpen: (anime) => JournalDetailsView.openFromAnime(context, anime),
                  ),
        ),
      ),
      SliverToBoxAdapter(
        child: AnimePosterRow(
          items: items,
          leading: AddPosterCard(onTap: onAdd),
          onTap: (anime) => JournalDetailsView.openFromAnime(context, anime),
        ),
      ),
    ];
  }
}
