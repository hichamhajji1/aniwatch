import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/reminder_time.dart';
import '../../data/models/anime_kind.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/journal_shelf.dart';
import '../../data/services/journal_files.dart';
import '../../data/services/notification_service.dart';
import '../../state/journal_provider.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/journal_cover.dart';

class AddEntrySheet {
  static Future<void> show(
    BuildContext context, {
    AnimeKind? kind,
    JournalEntry? entry,
    JournalShelf? shelf,
    bool forSaved = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => AddEntryPage(
          kind: kind,
          entry: entry,
          shelf: shelf,
          forSaved: forSaved,
        ),
      ),
    );
  }
}

class AddEntryPage extends StatelessWidget {
  const AddEntryPage({
    super.key,
    this.kind,
    this.entry,
    this.shelf,
    this.forSaved = false,
  });

  final AnimeKind? kind;
  final JournalEntry? entry;
  final JournalShelf? shelf;
  final bool forSaved;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AddEntrySheetBody(
        kind: kind,
        entry: entry,
        shelf: shelf,
        forSaved: forSaved,
      ),
    );
  }
}

class AddEntrySheetBody extends StatefulWidget {
  const AddEntrySheetBody({
    super.key,
    this.kind,
    this.entry,
    this.shelf,
    this.forSaved = false,
  });

  final AnimeKind? kind;
  final JournalEntry? entry;
  final JournalShelf? shelf;
  final bool forSaved;

  @override
  State<AddEntrySheetBody> createState() => _AddEntrySheetBodyState();
}

class _AddEntrySheetBodyState extends State<AddEntrySheetBody> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _kindId;
  String? _format;
  String? _imagePath;
  Uint8List? _imageBytes;
  DateTime? _reminderAt;
  String? _reminderError;
  WatchStatus _status = WatchStatus.queued;
  bool _saved = false;
  bool _busy = false;
  double? _score;

  bool get _editing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _description = TextEditingController(text: entry?.description ?? '');
    _kindId = entry?.kindId ?? widget.shelf?.kindId ?? widget.kind?.id ?? AnimeKind.comedy.id;
    _format = entry?.format ?? widget.shelf?.format;
    _imagePath = entry?.imagePath;
    _reminderAt = entry?.reminderAt;
    _status = entry?.status ?? WatchStatus.queued;
    _saved = entry?.saved ?? widget.forSaved;
    _score = entry?.score;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        _showPickError('That photo could not be read. Try another one.');
        return;
      }

      final id = widget.entry?.id ?? 'draft_${DateTime.now().microsecondsSinceEpoch}';
      final savedPath = await persistJournalBytes(bytes, id);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imagePath = savedPath ?? picked.path;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showPickError(
        error.code == 'photo_access_denied' || error.code == 'camera_access_denied'
            ? 'Allow Photos and Camera for AnShow Anime show in iPhone Settings, then try again.'
            : 'Could not open the photo picker. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      _showPickError('Could not load that image from your phone. Please try again.');
    }
  }

  void _showPickError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickReminder() async {
    final initial = _reminderAt ?? ReminderTime.inMinutes(5);
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await ReminderTime.pickTime(context, TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    setState(() {
      _reminderAt = ReminderTime.upcoming(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
      _reminderError = null;
    });
  }

  void _setQuickReminder(DateTime when) {
    setState(() {
      _reminderAt = ReminderTime.upcoming(when);
      _reminderError = null;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this anime a name first.')),
      );
      return;
    }
    setState(() => _busy = true);
    final journal = context.read<JournalProvider>();
    try {
      if (_editing) {
        final base = widget.entry!;
        var next = base.copyWith(
          title: title,
          description: _description.text.trim(),
          kindId: _kindId,
          format: _format,
          imagePath: _imagePath,
          reminderAt: _reminderAt,
          status: _status,
          shelfId: widget.shelf?.id ?? base.shelfId,
          saved: _saved,
          score: _score,
          clearScore: _score == null,
          clearReminder: _reminderAt == null,
        );
        if (_imagePath != null && _imagePath != base.imagePath) {
          final saved = await journal.saveCover(next, _imagePath!);
          next = next.copyWith(imagePath: saved);
        }
        await journal.update(next);
        if (_reminderAt != null) {
          await journal.setReminder(next, _reminderAt!);
        } else if (base.reminderAt != null) {
          await journal.clearReminder(next);
        }
      } else {
        await journal.add(
          title: title,
          description: _description.text,
          kindId: _kindId,
          format: _format,
          imagePath: _imagePath,
          reminderAt: _reminderAt,
          status: _status,
          shelfId: widget.shelf?.id,
          saved: _saved,
          score: _score,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Updated $title.'
                : _saved
                    ? '$title added to Saved.'
                    : '$title added to your journal.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = ReminderTime.messageFor(error);
      setState(() => _reminderError = message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = AnimeKind.byId(_kindId);
    final preview = JournalEntry(
      id: widget.entry?.id ?? 'preview',
      title: _title.text.trim().isEmpty ? 'New title' : _title.text,
      description: _description.text,
      kindId: _kindId,
      format: _format,
      imagePath: _imagePath,
      createdAt: DateTime.now(),
    );
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.gold,
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      _editing
                          ? 'Edit title'
                          : widget.forSaved
                              ? 'Add to Saved'
                              : 'Add to your journal',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _saved = !_saved),
                    icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    color: AppColors.gold,
                    tooltip: _saved ? 'Remove from Saved' : 'Add to Saved',
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text(
              _editing
                  ? 'Update the cover, story, or reminder.'
                  : widget.forSaved
                      ? 'This title will show up in Saved. You can still find it on Home.'
                      : widget.shelf != null
                          ? 'This title will be saved in ${widget.shelf!.title}. Bookmark it if you also want it in Saved.'
                          : 'You chose ${kind.label}. Name it, add a cover, and write why you want to watch it.',
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 148,
                    height: 210,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: kind.glow.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: JournalCover(
                        entry: preview,
                        previewBytes: _imageBytes,
                        showKind: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CoverAction(
                        icon: Icons.photo_library_rounded,
                        label: 'Photos',
                        onTap: () => _pickCover(ImageSource.gallery),
                      ),
                      const SizedBox(width: 10),
                      _CoverAction(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        onTap: () => _pickCover(ImageSource.camera),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SavedToggleButton(
                    saved: _saved,
                    onPressed: () => setState(() => _saved = !_saved),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              inputFormatters: [LengthLimitingTextInputFormatter(80)],
              decoration: const InputDecoration(
                hintText: 'Anime name',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Why this one? A note only you will see.',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = (index + 1).toDouble();
                  final selected = _score == value;
                  return ChoiceChip(
                    avatar: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: selected ? const Color(0xFF1A1408) : AppColors.gold,
                    ),
                    label: Text(value.toStringAsFixed(1)),
                    selected: selected,
                    onSelected: (_) => setState(() => _score = selected ? null : value),
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
            const SizedBox(height: 16),
            const Text('Kind', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AnimeKind.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = AnimeKind.all[index];
                  final selected = item.id == _kindId;
                  return ChoiceChip(
                    label: Text(item.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _kindId = item.id),
                    selectedColor: item.glow,
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF1A1408) : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppColors.chip,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            const Text('Format', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AnimeFormat.filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = AnimeFormat.filters[index];
                  if (filter.$2 == null) {
                    final selected = _format == null;
                    return ChoiceChip(
                      label: const Text('Any'),
                      selected: selected,
                      onSelected: (_) => setState(() => _format = null),
                      selectedColor: AppColors.gold,
                      labelStyle: TextStyle(
                        color: selected ? const Color(0xFF1A1408) : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: AppColors.chip,
                    );
                  }
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
            const SizedBox(height: 14),
            const Text('Where are you with it?', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final status in WatchStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                    selectedColor: status.color,
                    labelStyle: TextStyle(
                      color: _status == status ? const Color(0xFF1A1408) : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppColors.chip,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickReminder,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            _reminderAt == null
                                ? 'Optional — get a lock-screen nudge'
                                : DateFormatter.medium(_reminderAt!),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_reminderAt != null)
                      IconButton(
                        onPressed: () => setState(() {
                          _reminderAt = null;
                          _reminderError = null;
                        }),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ReminderQuickPicks(onPicked: _setQuickReminder),
            if (_reminderError != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold),
                ),
                child: Text(_reminderError!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 20),
            GoldButton(
              label: _busy
                  ? 'Saving…'
                  : (_editing
                      ? 'Save changes'
                      : (_saved ? 'Add to Saved' : 'Add to journal')),
              icon: _editing ? Icons.check_rounded : Icons.auto_awesome_rounded,
              glow: true,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SavedToggleButton extends StatelessWidget {
  const _SavedToggleButton({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: saved
          ? GoldButton(
              label: 'Saved',
              icon: Icons.bookmark_rounded,
              onPressed: onPressed,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_add_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Add to Saved', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
    );
  }
}

class _CoverAction extends StatelessWidget {
  const _CoverAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chip,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showJournalReminderPicker(BuildContext context, JournalEntry entry) async {
  final journal = context.read<JournalProvider>();
  final messenger = ScaffoldMessenger.of(context);
  var when = ReminderTime.upcoming(entry.reminderAt ?? ReminderTime.inMinutes(5));
  String? error;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: StatefulBuilder(
          builder: (context, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Remind me to watch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(entry.title, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ReminderQuickPicks(
                  onPicked: (picked) => setModal(() {
                    when = ReminderTime.upcoming(picked);
                    error = null;
                  }),
                ),
                const SizedBox(height: 12),
                GoldButton(
                  label: 'Date · ${DateFormatter.short(when)}',
                  expand: true,
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: when.isBefore(DateTime.now()) ? DateTime.now() : when,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;
                    setModal(() {
                      when = ReminderTime.upcoming(
                        DateTime(date.year, date.month, date.day, when.hour, when.minute),
                      );
                      error = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'Time · ${TimeOfDay.fromDateTime(when).format(context)}',
                  expand: true,
                  onPressed: () async {
                    final time = await ReminderTime.pickTime(context, TimeOfDay.fromDateTime(when));
                    if (time == null) return;
                    setModal(() {
                      when = ReminderTime.upcoming(
                        DateTime(when.year, when.month, when.day, time.hour, time.minute),
                      );
                      error = null;
                    });
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: AppColors.gold, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                GoldButton(
                  label: 'Set reminder',
                  glow: true,
                  onPressed: () async {
                    try {
                      final result = await journal.setReminder(entry, when);
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      final scheduled = ReminderTime.upcoming(when);
                      final message = switch (result) {
                        NotificationPermissionResult.denied =>
                          'Reminder saved, but notification permission was denied.',
                        NotificationPermissionResult.unavailable =>
                          'Reminder saved on this device. Lock-screen alerts are unavailable here.',
                        NotificationPermissionResult.granted =>
                          'Reminder set for ${DateFormatter.medium(scheduled)}.',
                      };
                      messenger.showSnackBar(SnackBar(content: Text(message)));
                    } catch (err) {
                      setModal(() => error = ReminderTime.messageFor(err));
                    }
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
