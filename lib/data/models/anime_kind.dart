import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AnimeKind {
  const AnimeKind({
    required this.id,
    required this.label,
    required this.prompt,
    required this.icon,
    required this.glow,
    required this.depth,
  });

  final String id;
  final String label;
  final String prompt;
  final IconData icon;
  final Color glow;
  final Color depth;

  static const action = AnimeKind(
    id: 'action',
    label: 'Action',
    prompt: 'Battles, power, and adrenaline.',
    icon: Icons.bolt_rounded,
    glow: Color(0xFFFF7A59),
    depth: Color(0xFF3A1410),
  );
  static const romance = AnimeKind(
    id: 'romance',
    label: 'Romance',
    prompt: 'Soft nights and slow-burn hearts.',
    icon: Icons.favorite_rounded,
    glow: Color(0xFFFF8FB3),
    depth: Color(0xFF3A1020),
  );
  static const fantasy = AnimeKind(
    id: 'fantasy',
    label: 'Fantasy',
    prompt: 'Magic, kingdoms, and destinies.',
    icon: Icons.auto_awesome_rounded,
    glow: Color(0xFFC9A2FF),
    depth: Color(0xFF1C1233),
  );
  static const sliceOfLife = AnimeKind(
    id: 'slice',
    label: 'Slice of Life',
    prompt: 'Quiet days that stay with you.',
    icon: Icons.wb_twilight_rounded,
    glow: Color(0xFF7DCEA0),
    depth: Color(0xFF10241C),
  );
  static const comedy = AnimeKind(
    id: 'comedy',
    label: 'Comedy',
    prompt: 'Laughs, chaos, and found family.',
    icon: Icons.sentiment_very_satisfied_rounded,
    glow: Color(0xFFFFC857),
    depth: Color(0xFF2A210C),
  );
  static const thriller = AnimeKind(
    id: 'thriller',
    label: 'Thriller',
    prompt: 'Tension you cannot pause.',
    icon: Icons.visibility_rounded,
    glow: Color(0xFFFF6B6B),
    depth: Color(0xFF2A0E12),
  );
  static const sciFi = AnimeKind(
    id: 'scifi',
    label: 'Sci-Fi',
    prompt: 'Future worlds and impossible tech.',
    icon: Icons.rocket_launch_rounded,
    glow: Color(0xFF7EC8FF),
    depth: Color(0xFF0E1A2A),
  );
  static const horror = AnimeKind(
    id: 'horror',
    label: 'Horror',
    prompt: 'Shadows, curses, and late nights.',
    icon: Icons.nights_stay_rounded,
    glow: Color(0xFFB388FF),
    depth: Color(0xFF1A1024),
  );
  static const sports = AnimeKind(
    id: 'sports',
    label: 'Sports',
    prompt: 'Rivalries, grit, and last seconds.',
    icon: Icons.sports_basketball_rounded,
    glow: Color(0xFFFFB347),
    depth: Color(0xFF2A1A0C),
  );
  static const mystery = AnimeKind(
    id: 'mystery',
    label: 'Mystery',
    prompt: 'Clues, secrets, and late-night twists.',
    icon: Icons.psychology_alt_rounded,
    glow: Color(0xFF8E9AAF),
    depth: Color(0xFF161820),
  );

  static const List<AnimeKind> all = [
    action,
    romance,
    fantasy,
    sliceOfLife,
    comedy,
    thriller,
    sciFi,
    horror,
    sports,
    mystery,
  ];

  static AnimeKind byId(String? id) {
    for (final kind in all) {
      if (kind.id == id) return kind;
    }
    return comedy;
  }
}

class AnimeFormat {
  const AnimeFormat._();

  static const filters = <(String label, String? value)>[
    ('All', null),
    ('TV', 'tv'),
    ('Movie', 'movie'),
    ('OVA', 'ova'),
    ('ONA', 'ona'),
    ('Special', 'special'),
  ];

  static String labelFor(String? value) {
    for (final filter in filters) {
      if (filter.$2 == value) return filter.$1;
    }
    return 'Title';
  }
}

enum WatchStatus { queued, watching, finished }

extension WatchStatusX on WatchStatus {
  String get label => switch (this) {
        WatchStatus.queued => 'Want to watch',
        WatchStatus.watching => 'Watching',
        WatchStatus.finished => 'Finished',
      };

  Color get color => switch (this) {
        WatchStatus.queued => AppColors.gold,
        WatchStatus.watching => AppColors.coral,
        WatchStatus.finished => AppColors.success,
      };
}
