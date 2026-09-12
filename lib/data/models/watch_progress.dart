import '../../core/utils/date_formatter.dart';

class WatchProgress {
  WatchProgress({
    required this.animeId,
    required this.animeTitle,
    required this.updatedAt,
    this.imageUrl,
    this.totalEpisodes,
    Set<int>? completedEpisodes,
  }) : completedEpisodes = completedEpisodes ?? <int>{};

  final int animeId;
  final String animeTitle;
  final String? imageUrl;
  final int? totalEpisodes;
  final Set<int> completedEpisodes;
  final DateTime updatedAt;

  int get watchedCount => completedEpisodes.length;

  bool get isComplete =>
      totalEpisodes != null && totalEpisodes! > 0 && watchedCount >= totalEpisodes!;

  double get fraction {
    if (totalEpisodes == null || totalEpisodes! <= 0) {
      return watchedCount == 0 ? 0 : 0.15;
    }
    return (watchedCount / totalEpisodes!).clamp(0, 1);
  }

  factory WatchProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['completedEpisodes'];
    final completed = <int>{};
    if (raw is List) {
      for (final item in raw) {
        if (item is num) completed.add(item.toInt());
      }
    }
    return WatchProgress(
      animeId: (json['animeId'] as num?)?.toInt() ?? 0,
      animeTitle: json['animeTitle'] as String? ?? 'Anime',
      imageUrl: json['imageUrl'] as String?,
      totalEpisodes: (json['totalEpisodes'] as num?)?.toInt(),
      completedEpisodes: completed,
      updatedAt: DateFormatter.tryParse(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'animeId': animeId,
        'animeTitle': animeTitle,
        'imageUrl': imageUrl,
        'totalEpisodes': totalEpisodes,
        'completedEpisodes': completedEpisodes.toList()..sort(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
