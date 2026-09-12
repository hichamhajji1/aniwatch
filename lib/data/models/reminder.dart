import '../../core/utils/date_formatter.dart';

class Reminder {
  const Reminder({
    required this.id,
    required this.animeId,
    required this.animeTitle,
    required this.scheduledAt,
    this.imageUrl,
  });

  final String id;
  final int animeId;
  final String animeTitle;
  final DateTime scheduledAt;
  final String? imageUrl;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String? ?? '${json['animeId']}',
      animeId: (json['animeId'] as num?)?.toInt() ?? 0,
      animeTitle: json['animeTitle'] as String? ?? 'Anime',
      scheduledAt: DateFormatter.tryParse(json['scheduledAt']) ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'animeId': animeId,
        'animeTitle': animeTitle,
        'scheduledAt': scheduledAt.toIso8601String(),
        'imageUrl': imageUrl,
      };
}
