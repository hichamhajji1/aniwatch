import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../core/utils/debouncer.dart';
import '../../data/services/remote_config_service.dart';
import '../../state/catalog_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../details/anime_details_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    this.autoFocus = false,
    this.initialQuery = '',
    this.queryToken = 0,
  });

  final bool autoFocus;
  final String initialQuery;
  final int queryToken;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 320));
  String? _type;

  static const _filters = <(String label, String? value)>[
    ('All', null),
    ('TV', 'tv'),
    ('Movie', 'movie'),
    ('OVA', 'ova'),
    ('ONA', 'ona'),
    ('Special', 'special'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<RemoteConfigService>().showAds) {
        context.read<CatalogProvider>().search(_controller.text, type: _type);
      }
      if (widget.autoFocus) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant SearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryToken != oldWidget.queryToken) {
      _controller.text = widget.initialQuery;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      _searchNow(_controller.text);
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
    _debouncer.dispose();
    super.dispose();
  }

  void _searchNow(String value) {
    _debouncer.cancel();
    if (!context.read<RemoteConfigService>().showAds) return;
    context.read<CatalogProvider>().search(value, type: _type);
  }

  void _onQuery(String value) {
    setState(() {});
    _debouncer.run(() {
      if (!mounted) return;
      if (!context.read<RemoteConfigService>().showAds) return;
      context.read<CatalogProvider>().search(value, type: _type);
    });
  }

  void _selectType(String? type) {
    setState(() => _type = type);
    _searchNow(_controller.text);
  }

  void _clear() {
    _controller.clear();
    _searchNow('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final showAds = context.read<RemoteConfigService>().showAds;

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
              onChanged: _onQuery,
              onSubmitted: _searchNow,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search anime',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clear,
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      ),
              ),
            ),
          ),
          if (showAds && catalog.searching)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final selected = _type == filter.$2;
                return ChoiceChip(
                  label: Text(filter.$1),
                  selected: selected,
                  onSelected: (_) => _selectType(filter.$2),
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
            child: showAds
                ? AnimatedSwitcher(
                    duration: AniMotion.fast,
                    switchInCurve: AniMotion.curve,
                    switchOutCurve: Curves.easeInCubic,
                    child: _buildBody(catalog),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CatalogProvider catalog) {
    final querying = _controller.text.trim().isNotEmpty || _type != null;
    final items = querying ? catalog.searchResults : (catalog.searchResults.isNotEmpty ? catalog.searchResults : catalog.catalog);

    if (catalog.searching && items.isEmpty) {
      return const PosterShimmerRow(key: ValueKey('search-loading'));
    }
    if (items.isEmpty) {
      return const Center(
        key: ValueKey('search-empty'),
        child: Text('No titles matched that search.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      key: const ValueKey('search-grid'),
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
          onTap: () => AnimeDetailsView.open(context, anime),
        );
      },
    );
  }
}
