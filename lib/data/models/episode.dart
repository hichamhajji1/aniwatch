import '../../core/utils/date_formatter.dart';

class Episode {
  const Episode({
    required this.malId,
    required this.title,
    this.titleJapanese,
    this.titleRomanji,
    this.aired,
    this.filler = false,
    this.recap = false,
    this.score,
  });

  final int malId;
  final String title;
  final String? titleJapanese;
  final String? titleRomanji;
  final DateTime? aired;
  final bool filler;
  final bool recap;
  final double? score;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      malId: (json['mal_id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Episode',
      titleJapanese: json['title_japanese'] as String?,
      titleRomanji: json['title_romanji'] as String?,
      aired: DateFormatter.tryParse(json['aired']),
      filler: json['filler'] == true,
      recap: json['recap'] == true,
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'mal_id': malId,
        'title': title,
        'title_japanese': titleJapanese,
        'title_romanji': titleRomanji,
        'aired': aired?.toIso8601String(),
        'filler': filler,
        'recap': recap,
        'score': score,
      };
}
