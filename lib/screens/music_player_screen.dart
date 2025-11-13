import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_player_provider.dart';
import '../models/downloaded_song.dart';

class MusicPlayerScreen extends StatelessWidget {
  final DownloadedSong song;
  final List<DownloadedSong>? playlist;
  final String? playlistName;

  const MusicPlayerScreen({
    super.key,
    required this.song,
    this.playlist,
    this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize player with song when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<MusicPlayerProvider>();
      if (player.currentSong?.id != song.id) {
        player.playSong(
          song,
          playlist: playlist,
          index: playlist?.indexWhere((s) => s.id == song.id),
          playlistName: playlistName,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<MusicPlayerProvider>(
          builder: (context, player, child) {
            final currentSong = player.currentSong ?? song;
            final currentPlaylistName = player.currentPlaylistName ?? playlistName;
            
            return Column(
              children: [
                // Header
                _buildHeader(context, player, currentPlaylistName),
                
                // Album Art
                Expanded(
                  child: _buildAlbumArt(context, currentSong),
                ),
                
                // Song Info and Controls
                _buildControls(context, player, currentSong),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MusicPlayerProvider player, String? currentPlaylistName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  currentPlaylistName != null 
                      ? 'MEMAINKAN DARI PLAYLIST'
                      : 'MEMAINKAN DARI LIBRARY',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (currentPlaylistName != null)
                  Text(
                    currentPlaylistName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Show menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context, DownloadedSong song) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            song.thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    size: 100,
                    color: Colors.white54,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    MusicPlayerProvider player,
    DownloadedSong song,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lyrics Button
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: Show lyrics
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur lirik akan segera hadir'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.description, size: 18, color: Colors.white70),
                label: const Text(
                  'Lirik',
                  style: TextStyle(color: Colors.white70),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Song Title and Artist
          Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Artist', // TODO: Get artist from song metadata
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: Color(0xFF1DB954), size: 16),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress Bar
          _buildProgressBar(context, player),
          const SizedBox(height: 24),
          
          // Playback Controls
          _buildPlaybackControls(context, player),
          const SizedBox(height: 24),
          
          // Secondary Controls
          _buildSecondaryControls(context, player),
          const SizedBox(height: 16),
          
          // Preview Lyrics Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Show preview lyrics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur pratinjau lirik akan segera hadir'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Pratinjau lirik'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    MusicPlayerProvider player,
  ) {
    final position = player.currentPosition;
    final duration = player.totalDuration;
    
    final positionText = '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}';
    final durationText = duration.inSeconds > 0
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '0:00';

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: const Color(0xFF1DB954),
            inactiveTrackColor: Colors.grey.shade700,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: duration.inSeconds > 0
                ? position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble())
                : 0.0,
            max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
            onChanged: (value) {
              player.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                positionText,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              Text(
                durationText,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(
    BuildContext context,
    MusicPlayerProvider player,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: player.isShuffleEnabled
                ? const Color(0xFF1DB954)
                : Colors.white70,
            size: 28,
          ),
          onPressed: () => player.toggleShuffle(),
        ),
        
        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
          onPressed: () => player.previousSong(),
        ),
        
        // Play/Pause
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              player.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 48,
            ),
            onPressed: () => player.togglePlayPause(),
            iconSize: 48,
            padding: EdgeInsets.zero,
          ),
        ),
        
        // Next
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
          onPressed: () => player.nextSong(),
        ),
        
        // Repeat
        IconButton(
          icon: Icon(
            player.isRepeatEnabled ? Icons.repeat_one : Icons.repeat,
            color: player.isRepeatEnabled
                ? const Color(0xFF1DB954)
                : Colors.white70,
            size: 28,
          ),
          onPressed: () => player.toggleRepeat(),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(
    BuildContext context,
    MusicPlayerProvider player,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Device
        IconButton(
          icon: const Icon(Icons.devices, color: Colors.white70, size: 24),
          onPressed: () {
            // TODO: Show device selection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur device selection akan segera hadir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        
        // Fast Rewind
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white70, size: 24),
          onPressed: () => player.fastRewind(),
        ),
        
        // Sleep Timer
        IconButton(
          icon: const Icon(Icons.timer_outlined, color: Colors.white70, size: 24),
          onPressed: () {
            // TODO: Show sleep timer
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur sleep timer akan segera hadir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        
        // Share
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white70, size: 24),
          onPressed: () {
            // TODO: Share song
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur share akan segera hadir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        
        // Queue
        IconButton(
          icon: const Icon(Icons.queue_music, color: Colors.white70, size: 24),
          onPressed: () {
            // TODO: Show queue
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur queue akan segera hadir'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

