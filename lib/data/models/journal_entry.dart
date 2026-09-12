import '../../core/utils/date_formatter.dart';
import 'anime.dart';
import 'anime_kind.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.kindId,
    required this.createdAt,
    this.format,
    this.imagePath,
    this.reminderAt,
    this.status = WatchStatus.queued,
    this.shelfId,
    this.saved = false,
    this.score,
    this.episodes,
    this.studio,
    this.source,
    this.duration,
    this.ageRating,
    this.extraKindIds = const [],
    this.watchSources = const [],
  });

  final String id;
  final String title;
  final String description;
  final String kindId;
  final String? format;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? reminderAt;
  final WatchStatus status;
  final String? shelfId;
  final bool saved;
  final double? score;
  final int? episodes;
  final String? studio;
  final String? source;
  final String? duration;
  final String? ageRating;
  final List<String> extraKindIds;
  final List<String> watchSources;

  AnimeKind get kind => AnimeKind.byId(kindId);

  List<String> get genreLabels {
    final ids = <String>[kindId, ...extraKindIds];
    final seen = <String>{};
    return [
      for (final id in ids)
        if (seen.add(id)) AnimeKind.byId(id).label,
    ];
  }

  String get monogram {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'A';
    return trimmed[0].toUpperCase();
  }

  int get notificationId => (id.hashCode & 0x7fffffff) % 100000000 + 800000000;

  Anime toAnime() {
    return Anime(
      malId: notificationId,
      title: title,
      imageUrl: imagePath,
      largeImageUrl: imagePath,
      synopsis: description,
      type: format == null ? kind.label : AnimeFormat.labelFor(format),
      status: status.label,
      episodes: episodes,
      source: source,
      duration: duration,
      rating: ageRating,
      score: score,
      genres: genreLabels,
      studios: studio == null || studio!.trim().isEmpty ? const [] : [studio!],
      year: createdAt.year,
      background: description,
    );
  }

  bool get hasReminder => reminderAt != null && reminderAt!.isAfter(DateTime.now().subtract(const Duration(minutes: 1)));

  JournalEntry copyWith({
    String? title,
    String? description,
    String? kindId,
    String? format,
    String? imagePath,
    DateTime? reminderAt,
    WatchStatus? status,
    String? shelfId,
    bool? saved,
    double? score,
    int? episodes,
    String? studio,
    String? source,
    String? duration,
    String? ageRating,
    List<String>? extraKindIds,
    List<String>? watchSources,
    bool clearReminder = false,
    bool clearImage = false,
    bool clearScore = false,
    bool clearEpisodes = false,
  }) {
    return JournalEntry(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      kindId: kindId ?? this.kindId,
      format: format ?? this.format,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      createdAt: createdAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      status: status ?? this.status,
      shelfId: shelfId ?? this.shelfId,
      saved: saved ?? this.saved,
      score: clearScore ? null : (score ?? this.score),
      episodes: clearEpisodes ? null : (episodes ?? this.episodes),
      studio: studio ?? this.studio,
      source: source ?? this.source,
      duration: duration ?? this.duration,
      ageRating: ageRating ?? this.ageRating,
      extraKindIds: extraKindIds ?? this.extraKindIds,
      watchSources: watchSources ?? this.watchSources,
    );
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      kindId: json['kindId'] as String? ?? AnimeKind.comedy.id,
      format: json['format'] as String?,
      imagePath: json['imagePath'] as String?,
      createdAt: DateFormatter.tryParse(json['createdAt']) ?? DateTime.now(),
      reminderAt: DateFormatter.tryParse(json['reminderAt']),
      status: WatchStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => WatchStatus.queued,
      ),
      shelfId: json['shelfId'] as String?,
      saved: json['saved'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble(),
      episodes: (json['episodes'] as num?)?.toInt(),
      studio: json['studio'] as String?,
      source: json['source'] as String?,
      duration: json['duration'] as String?,
      ageRating: json['ageRating'] as String?,
      extraKindIds: (json['extraKindIds'] as List?)?.whereType<String>().toList() ?? const [],
      watchSources: (json['watchSources'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'kindId': kindId,
        'format': format,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'reminderAt': reminderAt?.toIso8601String(),
        'status': status.name,
        'shelfId': shelfId,
        'saved': saved,
        'score': score,
        'episodes': episodes,
        'studio': studio,
        'source': source,
        'duration': duration,
        'ageRating': ageRating,
        'extraKindIds': extraKindIds,
        'watchSources': watchSources,
      };
}
