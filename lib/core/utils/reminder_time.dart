import 'package:flutter/material.dart';

class ReminderException implements Exception {
  ReminderException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ReminderTime {
  ReminderTime._();

  static DateTime upcoming(DateTime selected) {
    final now = DateTime.now().add(const Duration(seconds: 20));
    var when = DateTime(selected.year, selected.month, selected.day, selected.hour, selected.minute);
    if (when.isAfter(now)) return when;

    final looksLikeAmPmMixup =
        when.hour % 12 == now.hour % 12 && (when.minute - now.minute).abs() <= 15;
    final plusTwelve = when.add(const Duration(hours: 12));
    if (looksLikeAmPmMixup && plusTwelve.isAfter(now)) return plusTwelve;

    return when.add(const Duration(days: 1));
  }

  static DateTime inMinutes(int minutes) {
    return DateTime.now().add(Duration(minutes: minutes));
  }

  static String messageFor(Object error) {
    final text = error is ReminderException ? error.message : error.toString();
    return text
        .replaceFirst(RegExp(r'^Bad state:\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  static Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class ReminderQuickPicks extends StatelessWidget {
  const ReminderQuickPicks({super.key, required this.onPicked});

  final ValueChanged<DateTime> onPicked;

  static const _options = [
    (2, 'In 2 min'),
    (5, 'In 5 min'),
    (60, 'In 1 hour'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in _options)
          ActionChip(
            label: Text(option.$2),
            onPressed: () => onPicked(ReminderTime.inMinutes(option.$1)),
          ),
      ],
    );
  }
}
