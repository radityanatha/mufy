import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_info.dart';

class YouTubeService {
  final YoutubeExplode _ytExplode = YoutubeExplode();

  Future<VideoInfo> getVideoInfo(String url) async {
    try {
      final videoId = VideoId(url);
      final video = await _ytExplode.videos.get(videoId);
      
      return VideoInfo(
        id: video.id.value,
        title: video.title,
        thumbnail: video.thumbnails.mediumResUrl,
        duration: video.duration.toString().split('.').first,
        channelName: video.author,
      );
    } catch (e) {
      throw Exception('Gagal mengambil informasi video: $e');
    }
  }

  void dispose() {
    _ytExplode.close();
  }
}

