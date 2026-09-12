import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/reminder_time.dart';

enum NotificationPermissionResult { granted, denied, unavailable }

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _iosChannel = MethodChannel('anshow/ios_reminders');

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _tzReady = false;

  bool get isReady => _ready;
  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'anime_reminders',
      'Anime Reminders',
      channelDescription: 'Scheduled reminders to watch anime',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  Future<void> _ensureTimeZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (error) {
      debugPrint('NotificationService timezone fallback: $error');
      tz.setLocalLocation(tz.UTC);
    }
    _tzReady = true;
  }

  Future<void> init() async {
    await _ensureTimeZone();
    if (_ready || kIsWeb) {
      _ready = kIsWeb || _ready;
      return;
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: true,
          defaultPresentSound: true,
          defaultPresentBadge: true,
          defaultPresentBanner: true,
          defaultPresentList: true,
        ),
      );
      await _plugin.initialize(settings);
      await _ensureAndroidChannel();
      _ready = true;
    } catch (error, stack) {
      debugPrint('NotificationService.init failed: $error\n$stack');
    }
  }

  Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'anime_reminders',
        'Anime Reminders',
        description: 'Scheduled reminders to watch anime',
        importance: Importance.high,
      ),
    );
  }

  Future<NotificationPermissionResult> requestPermission() async {
    await init();
    if (kIsWeb) return NotificationPermissionResult.unavailable;

    if (_isIOS) {
      try {
        final granted = await _iosChannel.invokeMethod<bool>('request');
        return granted == true
            ? NotificationPermissionResult.granted
            : NotificationPermissionResult.denied;
      } catch (error) {
        debugPrint('iOS notification permission failed: $error');
        return NotificationPermissionResult.denied;
      }
    }

    if (!_ready) return NotificationPermissionResult.unavailable;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted == true
            ? NotificationPermissionResult.granted
            : NotificationPermissionResult.denied;
      }
      return NotificationPermissionResult.unavailable;
    } catch (error) {
      debugPrint('Notification permission failed: $error');
      return NotificationPermissionResult.unavailable;
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required DateTime when,
  }) async {
    await init();
    if (kIsWeb) return;

    final notificationId = id & 0x7fffffff;
    final local = ReminderTime.upcoming(when);
    final seconds = local.difference(DateTime.now()).inSeconds;
    if (seconds < 1) {
      throw ReminderException('That time already passed. Pick a time a few minutes from now.');
    }

    if (_isIOS) {
      await _iosChannel.invokeMethod<bool>('schedule', {
        'id': notificationId,
        'body': 'Time to watch $title',
        'seconds': seconds.toDouble(),
      });
      await _iosChannel.invokeMethod<bool>('show', {
        'id': 0x7ffffffe,
        'body': 'Reminder saved. I will alert you to watch $title.',
      });
      return;
    }

    if (!_ready) {
      throw ReminderException('Notifications are not available on this device yet. Restart the app and try again.');
    }

    await cancelReminder(notificationId);
    final scheduled = _zoned(local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
      throw ReminderException('That time already passed. Pick a time a few minutes from now.');
    }

    await _plugin.zonedSchedule(
      notificationId,
      'AnShow Anime show reminder',
      'Time to watch $title',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _zoned(DateTime when) {
    final local = when.toLocal();
    return tz.TZDateTime(
      tz.local,
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
  }

  Future<void> showNow({required int id, required String title}) async {
    await init();
    if (kIsWeb) return;
    final notificationId = id & 0x7fffffff;
    if (_isIOS) {
      await _iosChannel.invokeMethod<bool>('show', {
        'id': notificationId,
        'body': 'Time to watch $title',
      });
      return;
    }
    if (!_ready) return;
    await _plugin.cancel(notificationId);
    await _plugin.show(
      notificationId,
      'AnShow Anime show reminder',
      'Time to watch $title',
      _details,
    );
  }

  Future<void> cancelReminder(int id) async {
    await init();
    final notificationId = id & 0x7fffffff;
    if (_isIOS) {
      await _iosChannel.invokeMethod<void>('cancel', {'id': notificationId});
      return;
    }
    if (!_ready || kIsWeb) return;
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await init();
    if (_isIOS) {
      await _iosChannel.invokeMethod<void>('cancelAll');
      return;
    }
    if (!_ready || kIsWeb) return;
    await _plugin.cancelAll();
  }
}
