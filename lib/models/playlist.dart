class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final List<String> songIds; // List of song IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coverImage': coverImage,
        'songIds': songIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        coverImage: json['coverImage'],
        songIds: List<String>.from(json['songIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  int get songCount => songIds.length;
}

