import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/services/remote_config_service.dart';
import '../../data/services/storage_service.dart';
import '../../state/catalog_provider.dart';
import '../../state/journal_provider.dart';
import '../../state/reminder_provider.dart';
import '../../state/watchlist_provider.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/poster_image.dart';
import '../onboarding/onboarding_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<ReminderProvider>().displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      animationStyle: AnimationStyle(
        duration: AniMotion.fast,
        reverseDuration: AniMotion.fast,
        curve: AniMotion.curve,
      ),
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(title),
        content: Text(body, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _replayOnboarding() async {
    final storage = context.read<StorageService>();
    await storage.resetOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AniPageRoute(
        builder: (routeContext) => OnboardingView(
          onFinished: () async {
            await storage.setOnboardingComplete();
            if (!routeContext.mounted) return;
            Navigator.of(routeContext).pushAndRemoveUntil(
              AniPageRoute(builder: (_) => const MainShell()),
              (_) => false,
            );
          },
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final watchlist = context.watch<WatchlistProvider>();
    final catalog = context.watch<CatalogProvider>();
    final name = reminders.displayName.trim();
    final greeting = name.isEmpty ? 'Guest' : name;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Profile, library, notifications, and data stored on this device.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          _SectionLabel('Profile'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.chip,
                      child: Text(
                        greeting[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          const Text(
                            'Used on the Home greeting and reminder alerts.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Display name'),
                  onSubmitted: reminders.setDisplayName,
                  onChanged: (value) {
                    if (value.trim().length >= 2 || value.isEmpty) {
                      reminders.setDisplayName(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (context.read<RemoteConfigService>().showAds) ...[
            _SectionLabel('Library'),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(label: 'Bookmarks', value: '${watchlist.bookmarks.length}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Reminders', value: '${reminders.reminders.length}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Home titles', value: '${catalog.topAnime.length}'),
              ],
            ),
            const SizedBox(height: 22),
          ] else ...[
            _SectionLabel('Journal'),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(label: 'Titles', value: '${context.watch<JournalProvider>().entries.length}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Saved', value: '${context.watch<JournalProvider>().savedEntries.length}'),
                const SizedBox(width: 8),
                _StatCard(label: 'Watching', value: '${context.watch<JournalProvider>().entries.where((item) => item.status.name == 'watching').length}'),
              ],
            ),
            const SizedBox(height: 22),
          ],
          _SectionLabel('Notifications'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.gold,
            title: const Text('Lock-screen reminders', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text(
              'Alert you when a scheduled watch session is due. Can be turned off without deleting reminders.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            value: reminders.notificationsEnabled,
            onChanged: reminders.setNotificationsEnabled,
          ),
          const SizedBox(height: 8),
          if (context.read<RemoteConfigService>().showAds)
            if (reminders.reminders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No upcoming reminders. Open any anime and tap Reminder to add one.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...reminders.reminders.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 42,
                    height: 58,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PosterImage(
                        key: ValueKey('reminder-${item.animeId}'),
                        url: item.imageUrl,
                        malId: item.animeId,
                      ),
                    ),
                  ),
                  title: Text(item.animeTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(DateFormatter.medium(item.scheduledAt)),
                  trailing: IconButton(
                    onPressed: () => reminders.removeReminder(item.animeId),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  ),
                ),
              ),
          const SizedBox(height: 22),
          _SectionLabel('Data on this device'),
          if (context.read<RemoteConfigService>().showAds) ...[
            _SettingsTile(
              icon: Icons.bookmark_remove_outlined,
              title: 'Clear bookmarks',
              subtitle: 'Removes Saved titles from this device.',
              danger: true,
              onTap: () async {
                if (!await _confirm('Clear Saved lists?', 'Bookmarks will be removed from this device.')) {
                  return;
                }
                await watchlist.clearAll();
              },
            ),
            _SettingsTile(
              icon: Icons.notifications_off_outlined,
              title: 'Clear all reminders',
              subtitle: 'Deletes scheduled watch reminders and pending alerts.',
              danger: true,
              onTap: () async {
                if (!await _confirm('Clear reminders?', 'Every reminder on this device will be deleted.')) {
                  return;
                }
                await reminders.clearAll();
              },
            ),
            _SettingsTile(
              icon: Icons.replay_rounded,
              title: 'Replay onboarding',
              subtitle: 'Show the first-launch tour again. Your lists stay intact.',
              onTap: _replayOnboarding,
            ),
          ] else
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Clear journal',
              subtitle: 'Removes your titles, covers, and journal reminders from this device.',
              danger: true,
              onTap: () async {
                final journal = context.read<JournalProvider>();
                if (!await _confirm('Clear journal?', 'Every title you added will be deleted from this device.')) {
                  return;
                }
                await journal.clearAll();
              },
            ),
          const SizedBox(height: 28),
          const Text(
            'AnShow Anime show 1.0.0+1',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.gold;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }
}
