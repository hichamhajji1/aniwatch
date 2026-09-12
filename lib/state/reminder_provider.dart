import 'package:flutter/foundation.dart';

import '../core/utils/reminder_time.dart';
import '../data/models/anime.dart';
import '../data/models/reminder.dart';
import '../data/services/notification_service.dart';
import '../data/services/storage_service.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider(this._storage, this._notifications);

  final StorageService _storage;
  final NotificationService _notifications;

  final List<Reminder> _reminders = [];
  bool notificationsEnabled = true;
  String displayName = '';

  List<Reminder> get reminders {
    final items = [..._reminders]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  Future<void> load() async {
    notificationsEnabled = _storage.notificationsEnabled;
    displayName = _storage.displayName;
    _reminders
      ..clear()
      ..addAll(_storage.loadReminders());
    await _reschedulePending();
    notifyListeners();
  }

  Future<void> _reschedulePending() async {
    if (!notificationsEnabled) return;
    for (final reminder in _reminders) {
      if (!reminder.scheduledAt.isAfter(DateTime.now())) continue;
      try {
        await _notifications.scheduleReminder(
          id: reminder.animeId,
          title: reminder.animeTitle,
          when: reminder.scheduledAt,
        );
      } catch (error) {
        debugPrint('Could not restore reminder for ${reminder.animeTitle}: $error');
      }
    }
  }

  Future<void> setDisplayName(String value) async {
    displayName = value.trim();
    await _storage.setDisplayName(displayName);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    await _storage.setNotificationsEnabled(value);
    if (!value) {
      await _notifications.cancelAll();
    } else {
      for (final reminder in _reminders) {
        if (reminder.scheduledAt.isAfter(DateTime.now())) {
          await _notifications.scheduleReminder(
            id: reminder.animeId,
            title: reminder.animeTitle,
            when: reminder.scheduledAt,
          );
        }
      }
    }
    notifyListeners();
  }

  Reminder? reminderFor(int animeId) {
    try {
      return _reminders.firstWhere((item) => item.animeId == animeId);
    } catch (_) {
      return null;
    }
  }

  Future<NotificationPermissionResult> addReminder(Anime anime, DateTime when) async {
    final permission = await _notifications.requestPermission();
    if (permission != NotificationPermissionResult.granted &&
        permission != NotificationPermissionResult.unavailable) {
      return permission;
    }

    final scheduledAt = ReminderTime.upcoming(when);
    final reminder = Reminder(
      id: 'anime-${anime.malId}',
      animeId: anime.malId,
      animeTitle: anime.displayTitle,
      scheduledAt: scheduledAt,
      imageUrl: anime.poster,
    );
    _reminders.removeWhere((item) => item.animeId == anime.malId);
    _reminders.add(reminder);
    await _storage.saveReminders(_reminders);

    if (notificationsEnabled) {
      await _notifications.scheduleReminder(
        id: anime.malId,
        title: anime.displayTitle,
        when: scheduledAt,
      );
    }
    notifyListeners();
    return permission;
  }

  Future<void> removeReminder(int animeId) async {
    _reminders.removeWhere((item) => item.animeId == animeId);
    await _storage.saveReminders(_reminders);
    await _notifications.cancelReminder(animeId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _reminders.clear();
    await _storage.clearReminders();
    await _notifications.cancelAll();
    notifyListeners();
  }
}
