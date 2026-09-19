import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/anime.dart';
import '../../data/models/anime_kind.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/journal_shelf.dart';
import '../../data/models/streaming_link.dart';
import '../../data/services/remote_config_service.dart';
import '../../state/journal_provider.dart';
import '../../widgets/anime_trailer.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/rating_badge.dart';
import 'add_entry_sheet.dart';

class JournalDetailsView extends StatelessWidget {
  const JournalDetailsView({super.key, required this.entryId});

  final String entryId;

  static const _studios = [
    'MAPPA',
    'Ufotable',
    'Kyoto Animation',
    'Bones',
    'Wit Studio',
    'A-1 Pictures',
    'Madhouse',
    'Toei Animation',
    'Studio Ghibli',
    'Production I.G',
  ];
  static const _sources = ['Original', 'Manga', 'Light novel', 'Novel', 'Game', 'Web manga'];
  static const _durations = ['24 min per ep', '12 min per ep', '23 min per ep', '1 hr', '2 hr'];
  static const _ageRatings = ['G', 'PG', 'PG-13', 'R - 17+', 'R+'];

  static Future<void> open(BuildContext context, String entryId) {
    return Navigator.of(context).push(
      AniPageRoute(builder: (_) => JournalDetailsView(entryId: entryId)),
    );
  }

  static Future<void> openFromAnime(BuildContext context, Anime anime) {
    final entry = context.read<JournalProvider>().entryForMalId(anime.malId);
    if (entry == null) return Future.value();
    return open(context, entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<JournalProvider>();
    JournalEntry? entry;
    for (final item in journal.entries) {
      if (item.id == entryId) {
        entry = item;
        break;
      }
    }
    if (entry == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('This title is no longer in your journal.')),
      );
    }
    final current = entry;
    final details = current.toAnime();
    final shelf = current.shelfId == null ? null : JournalShelf.byId(current.shelfId!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            backgroundColor: AppColors.background,
            actions: [
              IconButton(
                onPressed: () => journal.toggleSaved(current),
                icon: Icon(current.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                color: AppColors.gold,
              ),
              IconButton(
                onPressed: () => AddEntrySheet.show(context, entry: current),
                icon: const Icon(Icons.edit_rounded),
                color: AppColors.gold,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PosterImage(
                    key: ValueKey('details-poster-${details.malId}-${details.poster}'),
                    url: details.poster,
                    malId: details.malId,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0xF20A0A0A)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          details.displayTitle,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
                        ),
                      ),
                      InkWell(
                        onTap: () => _pickScore(context, journal, current),
                        borderRadius: BorderRadius.circular(99),
                        child: current.score == null
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.star_border_rounded, color: AppColors.gold),
                              )
                            : RatingBadge(score: current.score!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      AnimeFormat.labelFor(current.format),
                      if (current.episodes != null) '${current.episodes} ep',
                      current.status.label,
                      DateFormatter.short(current.createdAt),
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: shelf?.title ?? 'Category',
                        onTap: () => _pickOption(
                          context,
                          title: 'Category',
                          options: [for (final item in JournalShelf.catalog) item.title],
                          onPick: (value) {
                            for (final item in JournalShelf.catalog) {
                              if (item.title == value) {
                                journal.update(current.copyWith(shelfId: item.id));
                                return;
                              }
                            }
                          },
                        ),
                      ),
                      _InfoChip(
                        label: current.studio ?? 'Studio',
                        onTap: () => _pickOption(
                          context,
                          title: 'Studio',
                          options: _studios,
                          onPick: (value) => journal.update(current.copyWith(studio: value)),
                        ),
                      ),
                      _InfoChip(
                        label: current.source ?? 'Source',
                        onTap: () => _pickOption(
                          context,
                          title: 'Source',
                          options: _sources,
                          onPick: (value) => journal.update(current.copyWith(source: value)),
                        ),
                      ),
                      _InfoChip(
                        label: current.duration ?? 'Duration',
                        onTap: () => _pickOption(
                          context,
                          title: 'Duration',
                          options: _durations,
                          onPick: (value) => journal.update(current.copyWith(duration: value)),
                        ),
                      ),
                      _InfoChip(
                        label: current.ageRating ?? 'Rating',
                        onTap: () => _pickOption(
                          context,
                          title: 'Rating',
                          options: _ageRatings,
                          onPick: (value) => journal.update(current.copyWith(ageRating: value)),
                        ),
                      ),
                      _InfoChip(
                        label: current.episodes == null ? 'Episodes' : '${current.episodes} ep',
                        onTap: () => _pickEpisodes(context, journal, current),
                      ),
                      _InfoChip(label: '${current.createdAt.year}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final kind in AnimeKind.all)
                        ChoiceChip(
                          label: Text(kind.label),
                          selected: current.kindId == kind.id || current.extraKindIds.contains(kind.id),
                          onSelected: (_) => _toggleGenre(journal, current, kind.id),
                          selectedColor: kind.glow,
                          labelStyle: TextStyle(
                            color: current.kindId == kind.id || current.extraKindIds.contains(kind.id)
                                ? const Color(0xFF1A1408)
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: AppColors.chip,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GoldButton(
                          label: current.saved ? 'Saved' : 'Bookmark',
                          icon: current.saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                          onPressed: () => journal.toggleSaved(current),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showJournalReminderPicker(context, current),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            side: const BorderSide(color: AppColors.gold),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  if (current.reminderAt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reminder set for ${DateFormatter.medium(current.reminderAt!)}',
                      style: const TextStyle(color: AppColors.gold, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    current.description.trim().isEmpty
                        ? 'No synopsis is available for this title.'
                        : current.description,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
                  ),
                  if (context.read<RemoteConfigService>().showAds) ...[
                    const SizedBox(height: 22),
                    const Text('Trailer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    AnimeTrailer(
                      key: ValueKey('trailer-${current.id}'),
                      videoId: null,
                      searchQuery: '${current.title} anime trailer',
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in AnimeFormat.filters)
                        if (filter.$2 != null)
                          ChoiceChip(
                            label: Text(filter.$1),
                            selected: current.format == filter.$2,
                            onSelected: (_) => journal.update(current.copyWith(format: filter.$2)),
                            selectedColor: AppColors.gold,
                            labelStyle: TextStyle(
                              color: current.format == filter.$2 ? const Color(0xFF1A1408) : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: AppColors.chip,
                          ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in WatchStatus.values)
                        ChoiceChip(
                          label: Text(status.label),
                          selected: current.status == status,
                          onSelected: (_) => journal.setStatus(current, status),
                          selectedColor: status.color,
                          labelStyle: TextStyle(
                            color: current.status == status ? const Color(0xFF1A1408) : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: AppColors.chip,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Watch legally', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final link in LegalSources.fallback)
                        ChoiceChip(
                          label: Text(link.name),
                          selected: current.watchSources.contains(link.name),
                          onSelected: (_) => _toggleWatchSource(journal, current, link.name),
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: current.watchSources.contains(link.name)
                                ? const Color(0xFF1A1408)
                                : AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: AppColors.chip,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove from journal?'),
                          content: Text('${current.title} will be deleted from this device.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !context.mounted) return;
                      await journal.remove(current);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Remove from journal', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleGenre(JournalProvider journal, JournalEntry current, String id) {
    if (current.kindId == id) return;
    final extra = [...current.extraKindIds];
    if (extra.contains(id)) {
      extra.remove(id);
    } else {
      extra.add(id);
    }
    journal.update(current.copyWith(extraKindIds: extra));
  }

  void _toggleWatchSource(JournalProvider journal, JournalEntry current, String name) {
    final sources = [...current.watchSources];
    if (sources.contains(name)) {
      sources.remove(name);
    } else {
      sources.add(name);
    }
    journal.update(current.copyWith(watchSources: sources));
  }

  Future<void> _pickOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required ValueChanged<String> onPick,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) onPick(selected);
  }

  Future<void> _pickScore(BuildContext context, JournalProvider journal, JournalEntry current) async {
    final scores = [for (var i = 10; i >= 1; i--) i.toDouble()];
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text('Your score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              ListTile(
                title: const Text('No score', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, 0),
              ),
              for (final score in scores)
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: AppColors.gold),
                  title: Text(score.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.pop(context, score),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    if (selected <= 0) {
      await journal.update(current.copyWith(clearScore: true));
    } else {
      await journal.update(current.copyWith(score: selected));
    }
  }

  Future<void> _pickEpisodes(BuildContext context, JournalProvider journal, JournalEntry current) async {
    var value = current.episodes ?? 12;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: StatefulBuilder(
              builder: (context, setModal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Episodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => setModal(() => value = (value - 1).clamp(1, 999)),
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.gold),
                        ),
                        Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        IconButton(
                          onPressed: () => setModal(() => value = (value + 1).clamp(1, 999)),
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GoldButton(
                      label: 'Save',
                      onPressed: () => Navigator.pop(context, value),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (selected != null) await journal.update(current.copyWith(episodes: selected));
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
