import '../../core/utils/json_map.dart';

class AnimeCharacter {
  const AnimeCharacter({
    required this.malId,
    required this.name,
    required this.role,
    this.imageUrl,
    this.voiceActorName,
    this.voiceActorImage,
    this.voiceActorLanguage,
  });

  final int malId;
  final String name;
  final String role;
  final String? imageUrl;
  final String? voiceActorName;
  final String? voiceActorImage;
  final String? voiceActorLanguage;

  factory AnimeCharacter.fromJson(Map<String, dynamic> json) {
    final character = asJsonMap(json['character']) ?? json;
    final images = asJsonMap(character['images']);
    final jpg = asJsonMap(images?['jpg']) ?? asJsonMap(images?['webp']);
    final actors = asJsonMapList(json['voice_actors']);
    Map<String, dynamic>? actor;
    for (final item in actors) {
      if ((item['language'] as String?)?.toLowerCase() == 'japanese') {
        actor = item;
        break;
      }
    }
    actor ??= actors.isEmpty ? null : actors.first;
    final person = asJsonMap(actor?['person']);
    final personImages = asJsonMap(person?['images']);
    final personJpg = asJsonMap(personImages?['jpg']);

    return AnimeCharacter(
      malId: (character['mal_id'] as num?)?.toInt() ?? 0,
      name: character['name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'Supporting',
      imageUrl: jpg?['image_url'] as String?,
      voiceActorName: person?['name'] as String?,
      voiceActorImage: personJpg?['image_url'] as String?,
      voiceActorLanguage: actor?['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'character': {
          'mal_id': malId,
          'name': name,
          'images': {
            'jpg': {'image_url': imageUrl},
          },
        },
        'role': role,
        'voice_actors': [
          if (voiceActorName != null)
            {
              'language': voiceActorLanguage,
              'person': {
                'name': voiceActorName,
                'images': {
                  'jpg': {'image_url': voiceActorImage},
                },
              },
            },
        ],
      };
}
