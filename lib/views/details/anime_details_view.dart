import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/anime.dart';
import '../../data/models/character.dart';
import '../../data/seed/seed_extras.dart';
import '../../data/services/remote_config_service.dart';
import '../../state/catalog_provider.dart';
import '../../state/reminder_provider.dart';
import '../../state/watchlist_provider.dart';
import '../../widgets/anime_trailer.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/shimmer_loader.dart';
import 'reminder_sheet.dart';

class AnimeDetailsView extends StatefulWidget {
  const AnimeDetailsView({super.key, required this.anime});

  final Anime anime;

  static Future<void> open(BuildContext context, Anime anime) {
    return Navigator.of(context).push(
      AniPageRoute(builder: (_) => AnimeDetailsView(anime: anime)),
    );
  }

  @override
  State<AnimeDetailsView> createState() => _AnimeDetailsViewState();
}

class _AnimeDetailsViewState extends State<AnimeDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadDetails(widget.anime.malId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final watchlist = context.watch<WatchlistProvider>();
    final reminders = context.watch<ReminderProvider>();
    final details = _resolvedDetails(catalog);
    final extrasReady = catalog.isFocused(widget.anime.malId);
    final saved = watchlist.isBookmarked(details.malId);
    final characters = extrasReady && catalog.characters.isNotEmpty
        ? catalog.characters
        : SeedExtras.characters(details.malId);
    final trailerId = details.playableTrailerId;
    final overview = _overviewText(details);
    final loadingOverview = extrasReady && catalog.loadingDetails && overview.startsWith('No synopsis');

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
                onPressed: () => watchlist.toggleBookmark(details),
                icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
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
                      if (details.score != null) RatingBadge(score: details.score!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      details.type,
                      if (details.episodes != null) '${details.episodes} ep',
                      details.status,
                      details.airedString,
                    ].whereType<String>().where((item) => item.isNotEmpty).join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (details.titleJapanese != null &&
                      details.titleJapanese!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      details.titleJapanese!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (details.studios.isNotEmpty)
                        _InfoChip(label: details.studios.take(2).join(', ')),
                      if (details.source != null && details.source!.isNotEmpty)
                        _InfoChip(label: details.source!),
                      if (details.duration != null && details.duration!.isNotEmpty)
                        _InfoChip(label: details.duration!),
                      if (details.rating != null && details.rating!.isNotEmpty)
                        _InfoChip(label: details.rating!),
                      if (details.rank != null) _InfoChip(label: 'Rank #${details.rank}'),
                      if (details.popularity != null)
                        _InfoChip(label: 'Popularity #${details.popularity}'),
                      if (details.season != null && details.year != null)
                        _InfoChip(label: '${details.season} ${details.year}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final genre in details.genres.take(8))
                        Chip(
                          label: Text(genre),
                          backgroundColor: AppColors.chip,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GoldButton(
                          label: saved ? 'Saved' : 'Bookmark',
                          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                          onPressed: () => watchlist.toggleBookmark(details),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ReminderSheet.show(context, details),
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
                  if (reminders.reminderFor(details.malId) != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reminder set for ${DateFormatter.medium(reminders.reminderFor(details.malId)!.scheduledAt)}',
                      style: const TextStyle(color: AppColors.gold, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (loadingOverview)
                    const Column(
                      children: [
                        ShimmerLoader(width: double.infinity, height: 12, radius: 6),
                        SizedBox(height: 8),
                        ShimmerLoader(width: double.infinity, height: 12, radius: 6),
                        SizedBox(height: 8),
                        ShimmerLoader(width: 220, height: 12, radius: 6),
                      ],
                    )
                  else
                    Text(
                      overview,
                      style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
                    ),
                  if (context.read<RemoteConfigService>().showAds) ...[
                    const SizedBox(height: 22),
                    const Text('Trailer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    AnimeTrailer(
                      key: ValueKey('trailer-${details.malId}-${trailerId ?? 'search'}'),
                      videoId: trailerId,
                      searchQuery: details.displayTitle,
                      loading: extrasReady && catalog.loadingDetails && trailerId == null,
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('Characters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (characters.isNotEmpty)
                    _CharacterRow(characters: characters)
                  else if (!extrasReady || catalog.loadingCharacters)
                    const _CharacterShimmer()
                  else
                    const Text(
                      'No character data is listed for this title.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 22),
                  const Text('Watch legally', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (catalog.streaming.isEmpty && catalog.loadingStreaming)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (catalog.streaming.isEmpty)
                    const Text(
                      'No official streaming sources are listed for this title.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else ...[
                    if (catalog.streaming.every((link) => link.url.trim().isEmpty))
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Look for this title on these official services. Availability depends on your region.',
                          style: TextStyle(color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final link in catalog.streaming) _SourceChip(label: link.name),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _overviewText(Anime details) {
    final fromDetails = details.synopsis?.trim() ?? '';
    if (fromDetails.isNotEmpty) return fromDetails;
    return SeedExtras.synopsis(details.malId) ??
        'No synopsis is available for this title.';
  }

  Anime _resolvedDetails(CatalogProvider catalog) {
    final remote = catalog.details;
    final base = (remote != null && remote.malId == widget.anime.malId) ? remote : widget.anime;
    return base.mergedWith(widget.anime);
  }
}

class _CharacterRow extends StatelessWidget {
  const _CharacterRow({required this.characters});

  final List<AnimeCharacter> characters;

  @override
  Widget build(BuildContext context) {
    final items = characters.take(24).toList();
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final character = items[index];
          return SizedBox(
            width: 92,
            child: Column(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: PosterImage(
                      key: ValueKey('char-${character.malId}'),
                      url: character.imageUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  character.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  character.voiceActorName ?? character.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CharacterShimmer extends StatelessWidget {
  const _CharacterShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const Column(
          children: [
            ShimmerLoader(width: 64, height: 64, radius: 32),
            SizedBox(height: 8),
            ShimmerLoader(width: 72, height: 10, radius: 6),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
