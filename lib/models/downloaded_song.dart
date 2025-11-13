class DownloadedSong {
  final String id;
  final String title;
  final String filePath;
  final String thumbnail;
  final DateTime downloadedAt;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.filePath,
    required this.thumbnail,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'thumbnail': thumbnail,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedSong.fromJson(Map<String, dynamic> json) => DownloadedSong(
        id: json['id'],
        title: json['title'],
        filePath: json['filePath'],
        thumbnail: json['thumbnail'],
        downloadedAt: DateTime.parse(json['downloadedAt']),
      );
}

