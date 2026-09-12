import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../data/models/anime_kind.dart';
import '../../state/journal_provider.dart';
import '../../widgets/anime_card.dart';
import 'add_entry_sheet.dart';
import 'journal_details_view.dart';

class JournalExploreView extends StatefulWidget {
  const JournalExploreView({
    super.key,
    this.autoFocus = false,
    this.initialQuery = '',
    this.queryToken = 0,
  });

  final bool autoFocus;
  final String initialQuery;
  final int queryToken;

  @override
  State<JournalExploreView> createState() => _JournalExploreViewState();
}

class _JournalExploreViewState extends State<JournalExploreView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _format;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoFocus && mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant JournalExploreView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryToken != oldWidget.queryToken) {
      _controller.text = widget.initialQuery;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      setState(() {});
    }
    if (widget.autoFocus && (!oldWidget.autoFocus || widget.queryToken != oldWidget.queryToken)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    final items = journal.search(query: _controller.text, format: _format).map((item) => item.toAnime()).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Explore', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search your anime',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: AnimeFormat.filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = AnimeFormat.filters[index];
                final selected = _format == filter.$2;
                return ChoiceChip(
                  label: Text(filter.$1),
                  selected: selected,
                  onSelected: (_) => setState(() => _format = filter.$2),
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF1A1408) : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: AppColors.chip,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: AniMotion.fast,
              child: items.isEmpty
                  ? Center(
                      key: const ValueKey('empty'),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No titles matched that search.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => AddEntrySheet.show(context),
                              child: const Text('Add a title', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      key: const ValueKey('grid'),
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
                          key: ValueKey('explore-${anime.malId}'),
                          width: double.infinity,
                          anime: anime,
                          onTap: () => JournalDetailsView.openFromAnime(context, anime),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
