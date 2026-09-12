import 'package:flutter/foundation.dart';

import '../core/utils/reminder_time.dart';
import '../data/models/anime.dart';
import '../data/models/anime_kind.dart';
import '../data/models/journal_entry.dart';
import '../data/models/journal_shelf.dart';
import '../data/services/journal_files.dart';
import '../data/services/notification_service.dart';
import '../data/services/storage_service.dart';

class JournalProvider extends ChangeNotifier {
  JournalProvider(this._storage, this._notifications);

  final StorageService _storage;
  final NotificationService _notifications;
  final List<JournalEntry> _entries = [];
  List<String> _homeShelfIds = List<String>.from(JournalShelf.defaultIds);

  List<JournalEntry> get entries {
    final items = [..._entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<JournalEntry> get chronological {
    final items = [..._entries]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  JournalEntry? get featuredEntry {
    final items = chronological;
    return items.isEmpty ? null : items.first;
  }

  List<Anime> get yourAnime {
    final items = chronological;
    if (items.length < 2) return const [];
    return items.skip(1).toList().reversed.map((item) => item.toAnime()).toList();
  }

  List<JournalShelf> get homeShelves =>
      _homeShelfIds.map(JournalShelf.byId).toList(growable: false);

  List<JournalShelf> get availableShelves => [
        for (final shelf in JournalShelf.catalog)
          if (!_homeShelfIds.contains(shelf.id)) shelf,
      ];

  JournalEntry? get tonightPick {
    final upcoming = reminderEntries;
    if (upcoming.isNotEmpty) return upcoming.first;
    return featuredEntry;
  }

  List<JournalEntry> get reminderEntries {
    final items = _entries.where((item) => item.reminderAt != null).toList()
      ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
    return items;
  }

  List<JournalEntry> byKind(String kindId) => entries.where((item) => item.kindId == kindId).toList();

  JournalEntry? entryForMalId(int malId) {
    for (final item in _entries) {
      if (item.notificationId == malId) return item;
    }
    return null;
  }

  List<Anime> get catalog => entries.map((item) => item.toAnime()).toList();

  List<JournalEntry> get savedEntries => entries.where((item) => item.saved).toList();

  List<Anime> get savedAnime => savedEntries.map((item) => item.toAnime()).toList();

  List<JournalEntry> get unsavedEntries => entries.where((item) => !item.saved).toList();

  List<Anime> animeByShelf(String shelfId) =>
      entries.where((item) => item.shelfId == shelfId).map((item) => item.toAnime()).toList();

  List<Anime> animeByFormat(String format) =>
      entries.where((item) => item.format == format).map((item) => item.toAnime()).toList();

  List<Anime> animeByStatus(WatchStatus status) =>
      entries.where((item) => item.status == status).map((item) => item.toAnime()).toList();

  List<JournalEntry> search({String query = '', String? format, String? kindId}) {
    final needle = query.trim().toLowerCase();
    return entries.where((item) {
      if (format != null && item.format != format) return false;
      if (kindId != null && item.kindId != kindId) return false;
      if (needle.isEmpty) return true;
      final shelfTitle =
          item.shelfId == null ? '' : JournalShelf.byId(item.shelfId!).title.toLowerCase();
      final formatLabel = AnimeFormat.labelFor(item.format).toLowerCase();
      return item.title.toLowerCase().contains(needle) ||
          item.description.toLowerCase().contains(needle) ||
          item.kind.label.toLowerCase().contains(needle) ||
          formatLabel.contains(needle) ||
          item.status.label.toLowerCase().contains(needle) ||
          shelfTitle.contains(needle);
    }).toList();
  }

  Future<void> load() async {
    _entries
      ..clear()
      ..addAll(_storage.loadJournal());
    _homeShelfIds = _withMainSections(_storage.loadHomeShelves());
    await _storage.saveHomeShelves(_homeShelfIds);
    await _reschedulePending();
    notifyListeners();
  }

  Future<void> _reschedulePending() async {
    if (!_storage.notificationsEnabled) return;
    for (final entry in _entries) {
      final when = entry.reminderAt;
      if (when == null || !when.isAfter(DateTime.now())) continue;
      try {
        await _schedule(entry, when);
      } catch (error) {
        debugPrint('Could not restore reminder for ${entry.title}: $error');
      }
    }
  }

  List<String> _withMainSections(List<String> saved) {
    final extras = [
      for (final id in saved)
        if (!JournalShelf.defaultIds.contains(id)) id,
    ];
    return [...JournalShelf.defaultIds, ...extras];
  }

  Future<void> _ensureShelf(String id) async {
    if (_homeShelfIds.contains(id)) return;
    _homeShelfIds = [..._homeShelfIds, id];
    await _storage.saveHomeShelves(_homeShelfIds);
  }

  Future<void> addHomeShelf(JournalShelf shelf) async {
    if (_homeShelfIds.contains(shelf.id)) return;
    _homeShelfIds = [..._homeShelfIds, shelf.id];
    await _storage.saveHomeShelves(_homeShelfIds);
    notifyListeners();
  }

  Future<JournalEntry> add({
    required String title,
    required String description,
    required String kindId,
    String? format,
    String? imagePath,
    DateTime? reminderAt,
    WatchStatus status = WatchStatus.queued,
    String? shelfId,
    bool saved = false,
    double? score,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final persisted = imagePath == null ? null : await persistJournalImage(imagePath, id);
    final resolvedShelf = shelfId ??
        JournalShelf.forFormat(format)?.id ??
        JournalShelf.forKind(kindId)?.id ??
        JournalShelf.top.id;
    var entry = JournalEntry(
      id: id,
      title: title.trim(),
      description: description.trim(),
      kindId: kindId,
      format: format,
      imagePath: persisted,
      createdAt: DateTime.now(),
      reminderAt: reminderAt == null ? null : ReminderTime.upcoming(reminderAt),
      status: status,
      shelfId: resolvedShelf,
      saved: saved,
      score: score,
    );
    if (reminderAt != null) {
      await _notifications.requestPermission();
      await _schedule(entry, entry.reminderAt!);
    }
    await _ensureShelf(resolvedShelf);
    _entries.insert(0, entry);
    await _storage.saveJournal(_entries);
    notifyListeners();
    return entry;
  }

  Future<void> update(JournalEntry entry) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    _entries[index] = entry;
    await _storage.saveJournal(_entries);
    notifyListeners();
  }

  Future<String?> saveCover(JournalEntry entry, String sourcePath) async {
    final path = await persistJournalImage(sourcePath, entry.id);
    await update(entry.copyWith(imagePath: path));
    return path;
  }

  Future<NotificationPermissionResult> setReminder(JournalEntry entry, DateTime when) async {
    final permission = await _notifications.requestPermission();
    if (permission != NotificationPermissionResult.granted &&
        permission != NotificationPermissionResult.unavailable) {
      return permission;
    }
    final scheduledAt = ReminderTime.upcoming(when);
    final next = entry.copyWith(reminderAt: scheduledAt);
    await _schedule(next, scheduledAt);
    await update(next);
    return permission;
  }

  Future<void> clearReminder(JournalEntry entry) async {
    await _notifications.cancelReminder(entry.notificationId);
    await update(entry.copyWith(clearReminder: true));
  }

  Future<void> setStatus(JournalEntry entry, WatchStatus status) {
    return update(entry.copyWith(status: status));
  }

  Future<void> setSaved(JournalEntry entry, bool saved) {
    return update(entry.copyWith(saved: saved));
  }

  Future<void> toggleSaved(JournalEntry entry) {
    return setSaved(entry, !entry.saved);
  }

  Future<void> remove(JournalEntry entry) async {
    await _notifications.cancelReminder(entry.notificationId);
    await deleteJournalImage(entry.imagePath);
    _entries.removeWhere((item) => item.id == entry.id);
    await _storage.saveJournal(_entries);
    notifyListeners();
  }

  Future<void> clearAll() async {
    for (final entry in _entries) {
      await _notifications.cancelReminder(entry.notificationId);
      await deleteJournalImage(entry.imagePath);
    }
    _entries.clear();
    await _storage.clearJournal();
    notifyListeners();
  }

  Future<void> _schedule(JournalEntry entry, DateTime when) async {
    if (!_storage.notificationsEnabled) return;
    await _notifications.scheduleReminder(
      id: entry.notificationId,
      title: entry.title,
      when: when,
    );
  }
}
