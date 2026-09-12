import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/anime.dart';
import '../../data/models/reminder.dart';
import '../../data/services/remote_config_service.dart';
import '../../state/journal_provider.dart';
import '../../state/reminder_provider.dart';
import '../../widgets/poster_image.dart';
import '../details/anime_details_view.dart';
import '../journal/journal_details_view.dart';

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    final showAds = context.watch<RemoteConfigService>().showAds;
    if (showAds) {
      final items = context.watch<ReminderProvider>().reminders;
      return _RemindersScaffold(
        items: [
          for (final item in items)
            _ReminderRowData(
              id: 'catalog-${item.animeId}',
              title: item.animeTitle,
              when: item.scheduledAt,
              imageUrl: item.imageUrl,
              malId: item.animeId,
              onTap: () => AnimeDetailsView.open(context, _animeFromReminder(item)),
            ),
        ],
      );
    }

    final items = context.watch<JournalProvider>().reminderEntries;
    return _RemindersScaffold(
      items: [
        for (final item in items)
          _ReminderRowData(
            id: 'journal-${item.id}',
            title: item.title,
            when: item.reminderAt!,
            imageUrl: item.imagePath,
            malId: item.notificationId,
            onTap: () => JournalDetailsView.open(context, item.id),
          ),
      ],
    );
  }

  Anime _animeFromReminder(Reminder item) {
    return Anime(
      malId: item.animeId,
      title: item.animeTitle,
      imageUrl: item.imageUrl,
      largeImageUrl: item.imageUrl,
    );
  }
}

class _ReminderRowData {
  const _ReminderRowData({
    required this.id,
    required this.title,
    required this.when,
    required this.onTap,
    this.imageUrl,
    this.malId,
  });

  final String id;
  final String title;
  final DateTime when;
  final String? imageUrl;
  final int? malId;
  final VoidCallback onTap;
}

class _RemindersScaffold extends StatelessWidget {
  const _RemindersScaffold({required this.items});

  final List<_ReminderRowData> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Reminders', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              items.isEmpty
                  ? 'Titles waiting for a reminder will show up here.'
                  : 'Anime waiting to remind you to watch.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_outlined, color: AppColors.gold, size: 42),
                          SizedBox(height: 16),
                          Text(
                            'Nothing is waiting yet. Open a title and tap Reminder.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ReminderTile(key: ValueKey(item.id), item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({super.key, required this.item});

  final _ReminderRowData item;

  @override
  Widget build(BuildContext context) {
    final due = item.when.isBefore(DateTime.now());
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 86,
                  child: PosterImage(url: item.imageUrl, malId: item.malId),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      due ? 'Due · ${DateFormatter.medium(item.when)}' : 'Waiting · ${DateFormatter.medium(item.when)}',
                      style: TextStyle(
                        color: due ? AppColors.coral : AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
