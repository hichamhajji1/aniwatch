import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/ani_motion.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/reminder_time.dart';
import '../../data/models/anime.dart';
import '../../data/services/notification_service.dart';
import '../../state/reminder_provider.dart';
import '../../widgets/gold_button.dart';

class ReminderSheet {
  static Future<void> show(BuildContext context, Anime anime) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      barrierColor: const Color(0x99000000),
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AniMotion.page,
        reverseDuration: AniMotion.pageReverse,
        curve: AniMotion.curve,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReminderSheetBody(anime: anime),
    );
  }
}

class _ReminderSheetBody extends StatefulWidget {
  const _ReminderSheetBody({required this.anime});

  final Anime anime;

  @override
  State<_ReminderSheetBody> createState() => _ReminderSheetBodyState();
}

class _ReminderSheetBodyState extends State<_ReminderSheetBody> {
  late DateTime _when = ReminderTime.inMinutes(5);
  bool _busy = false;
  String? _error;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when.isBefore(DateTime.now()) ? DateTime.now() : _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _when = ReminderTime.upcoming(DateTime(date.year, date.month, date.day, _when.hour, _when.minute));
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    final time = await ReminderTime.pickTime(context, TimeOfDay.fromDateTime(_when));
    if (time == null || !mounted) return;
    setState(() {
      _when = ReminderTime.upcoming(DateTime(_when.year, _when.month, _when.day, time.hour, time.minute));
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final scheduled = ReminderTime.upcoming(_when);
      final result = await context.read<ReminderProvider>().addReminder(widget.anime, scheduled);
      if (!mounted) return;
      Navigator.pop(context);
      final message = switch (result) {
        NotificationPermissionResult.denied => 'Reminder saved, but notification permission was denied.',
        NotificationPermissionResult.unavailable => 'Reminder saved on this device. Lock-screen alerts are unavailable here.',
        NotificationPermissionResult.granted => 'Reminder set for ${DateFormatter.medium(scheduled)}.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ReminderTime.messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remind me to watch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(widget.anime.displayTitle, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ReminderQuickPicks(
            onPicked: (picked) => setState(() {
              _when = ReminderTime.upcoming(picked);
              _error = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PickerTile(label: 'Date', value: DateFormatter.short(_when), onTap: _pickDate),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerTile(
                  label: 'Time',
                  value: TimeOfDay.fromDateTime(_when).format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.gold, fontSize: 13)),
          ],
          const SizedBox(height: 18),
          GoldButton(
            label: _busy ? 'Saving…' : 'Set reminder',
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
