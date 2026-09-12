import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/motion/ani_motion.dart';
import '../data/services/remote_config_service.dart';
import '../views/home/home_view.dart';
import '../views/journal/journal_explore_view.dart';
import '../views/journal/journal_home_view.dart';
import '../views/journal/journal_saved_view.dart';
import '../views/reminders/reminders_view.dart';
import '../views/search/search_view.dart';
import '../views/settings/settings_view.dart';
import '../views/watchlist/watchlist_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _focusSearch = false;
  String _searchQuery = '';
  int _searchToken = 0;

  void _goSearch([String query = '']) => setState(() {
        _index = 1;
        _focusSearch = true;
        _searchQuery = query;
        _searchToken++;
      });

  void _selectTab(int index) => setState(() {
        _index = index;
        if (index != 1) _focusSearch = false;
      });

  @override
  Widget build(BuildContext context) {
    final showAds = context.watch<RemoteConfigService>().showAds;
    final pages = showAds
        ? [
            HomeView(key: const PageStorageKey('home'), onOpenSearch: _goSearch),
            SearchView(
              key: const PageStorageKey('search'),
              autoFocus: _focusSearch,
              initialQuery: _searchQuery,
              queryToken: _searchToken,
            ),
            const WatchlistView(key: PageStorageKey('saved')),
            const RemindersView(key: PageStorageKey('reminders')),
            const SettingsView(key: PageStorageKey('settings')),
          ]
        : [
            JournalHomeView(key: const PageStorageKey('journal-home'), onOpenExplore: _goSearch),
            JournalExploreView(
              key: const PageStorageKey('journal-explore'),
              autoFocus: _focusSearch,
              initialQuery: _searchQuery,
              queryToken: _searchToken,
            ),
            const JournalSavedView(key: PageStorageKey('journal-saved')),
            const RemindersView(key: PageStorageKey('journal-reminders')),
            const SettingsView(key: PageStorageKey('settings')),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeIndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.charcoal,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: [
                _NavItem(
                  selected: _index == 0,
                  icon: Icons.play_circle_fill_rounded,
                  label: 'Anime',
                  onTap: () => _selectTab(0),
                  featured: true,
                ),
                _NavItem(
                  selected: _index == 1,
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                  onTap: () => _selectTab(1),
                ),
                _NavItem(
                  selected: _index == 2,
                  icon: Icons.bookmark_border_rounded,
                  label: 'Saved',
                  onTap: () => _selectTab(2),
                ),
                _NavItem(
                  selected: _index == 3,
                  icon: Icons.notifications_active_outlined,
                  label: 'Remind',
                  onTap: () => _selectTab(3),
                ),
                _NavItem(
                  selected: _index == 4,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => _selectTab(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.featured = false,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (featured)
                AnimatedContainer(
                  duration: AniMotion.fast,
                  curve: AniMotion.curve,
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : AppColors.chip,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? const Color(0xFF1A1408) : AppColors.textSecondary,
                  ),
                )
              else
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: AniMotion.fast,
                  curve: AniMotion.curve,
                  child: Icon(icon, color: color),
                ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: AniMotion.fast,
                curve: AniMotion.curve,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
