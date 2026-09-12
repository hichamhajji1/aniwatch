import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../models/anime.dart';
import '../models/journal_entry.dart';
import '../models/journal_shelf.dart';
import '../models/reminder.dart';
import '../models/watch_progress.dart';

class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  Future<void> setOnboardingComplete() {
    return _prefs.setBool(StorageKeys.onboardingComplete, true);
  }

  bool get onboardingComplete => _prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  String get displayName => _prefs.getString(StorageKeys.displayName) ?? '';

  Future<void> setDisplayName(String value) {
    return _prefs.setString(StorageKeys.displayName, value.trim());
  }

  bool get notificationsEnabled => _prefs.getBool(StorageKeys.notificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) {
    return _prefs.setBool(StorageKeys.notificationsEnabled, value);
  }

  List<Anime> loadWatchlist() {
    final envelope = _decodeWatchlistEnvelope();
    return envelope.$1;
  }

  List<Anime> loadWatchedHistory() => _decodeWatchlistEnvelope().$2;

  Future<void> saveWatchlist(List<Anime> bookmarks, {List<Anime>? watched}) {
    final history = watched ?? loadWatchedHistory();
    return _prefs.setString(
      StorageKeys.watchlist,
      jsonEncode({
        'bookmarks': bookmarks.map((item) => item.toJson()).toList(),
        'watched': history.map((item) => item.toJson()).toList(),
      }),
    );
  }

  Future<void> saveWatchedHistory(List<Anime> watched, {List<Anime>? bookmarks}) {
    final saved = bookmarks ?? loadWatchlist();
    return saveWatchlist(saved, watched: watched);
  }

  (List<Anime>, List<Anime>) _decodeWatchlistEnvelope() {
    final raw = _prefs.getString(StorageKeys.watchlist);
    if (raw == null || raw.isEmpty) return (const [], const []);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return (
          decoded
              .whereType<Map>()
              .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
          const [],
        );
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        return (_animeList(map['bookmarks']), _animeList(map['watched']));
      }
    } catch (_) {}
    return (const [], const []);
  }

  List<Anime> _animeList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<WatchProgress> loadProgress() =>
      _decodeList(StorageKeys.progress, WatchProgress.fromJson);

  Future<void> saveProgress(List<WatchProgress> items) {
    return _encodeList(StorageKeys.progress, items.map((item) => item.toJson()).toList());
  }

  List<Reminder> loadReminders() => _decodeList(StorageKeys.reminders, Reminder.fromJson);

  List<JournalEntry> loadJournal() => _decodeList(StorageKeys.journal, JournalEntry.fromJson);

  Future<void> saveJournal(List<JournalEntry> items) {
    return _encodeList(StorageKeys.journal, items.map((item) => item.toJson()).toList());
  }

  List<String> loadHomeShelves() {
    final raw = _prefs.getStringList(StorageKeys.journalShelves);
    if (raw == null || raw.isEmpty) return List<String>.from(JournalShelf.defaultIds);
    return raw;
  }

  Future<void> saveHomeShelves(List<String> ids) {
    return _prefs.setStringList(StorageKeys.journalShelves, ids);
  }

  Future<void> saveReminders(List<Reminder> items) {
    return _encodeList(StorageKeys.reminders, items.map((item) => item.toJson()).toList());
  }

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _encodeList(String key, List<Map<String, dynamic>> items) {
    return _prefs.setString(key, jsonEncode(items));
  }

  Future<void> clearWatchlist() => _prefs.remove(StorageKeys.watchlist);

  Future<void> clearProgress() => _prefs.remove(StorageKeys.progress);

  Future<void> clearReminders() => _prefs.remove(StorageKeys.reminders);

  Future<void> resetOnboarding() => _prefs.remove(StorageKeys.onboardingComplete);

  Future<void> clearJournal() => _prefs.remove(StorageKeys.journal);
}
