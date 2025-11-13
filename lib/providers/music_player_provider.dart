import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../models/downloaded_song.dart';

class MusicPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  DownloadedSong? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;
  String? _currentPlaylistName;
  
  List<DownloadedSong> _playlist = [];
  int _currentIndex = 0;

  DownloadedSong? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  String? get currentPlaylistName => _currentPlaylistName;
  List<DownloadedSong> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  MusicPlayerProvider() {
    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _onSongComplete();
    });
  }

  Future<void> playSong(
    DownloadedSong song, {
    List<DownloadedSong>? playlist,
    int? index,
    String? playlistName,
  }) async {
    try {
      // Stop current playback
      await _audioPlayer.stop();
      
      _currentSong = song;
      if (playlist != null && playlist.isNotEmpty) {
        _playlist = playlist;
        _currentIndex = index ?? playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _currentIndex = 0;
        }
      } else {
        _playlist = [song];
        _currentIndex = 0;
      }
      _currentPlaylistName = playlistName;
      
      // Check if file exists
      final file = File(song.filePath);
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan: ${song.filePath}');
      }

      // Play the file
      await _audioPlayer.play(DeviceFileSource(song.filePath));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing song: $e');
      _isPlaying = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      _isPlaying = !_isPlaying;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  Future<void> fastForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition <= _totalDuration) {
      await seek(newPosition);
    } else {
      await seek(_totalDuration);
    }
  }

  Future<void> fastRewind() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> nextSong() async {
    if (_playlist.isEmpty) return;
    
    try {
      int nextIndex;
      if (_isShuffleEnabled) {
        // Random song, but not the same as current
        do {
          nextIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length);
        } while (nextIndex == _currentIndex && _playlist.length > 1);
      } else {
        nextIndex = (_currentIndex + 1) % _playlist.length;
      }
      
      _currentIndex = nextIndex;
      await playSong(
        _playlist[_currentIndex],
        playlist: _playlist,
        index: _currentIndex,
        playlistName: _currentPlaylistName,
      );
    } catch (e) {
      debugPrint('Error playing next song: $e');
    }
  }

  Future<void> previousSong() async {
    if (_playlist.isEmpty) return;
    
    try {
      // If more than 3 seconds into song, restart current song
      if (_currentPosition.inSeconds > 3) {
        await seek(Duration.zero);
        return;
      }
      
      // Go to previous song
      int prevIndex;
      if (_isShuffleEnabled) {
        // Random song, but not the same as current
        do {
          prevIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length);
        } while (prevIndex == _currentIndex && _playlist.length > 1);
      } else {
        prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      }
      
      _currentIndex = prevIndex;
      await playSong(
        _playlist[_currentIndex],
        playlist: _playlist,
        index: _currentIndex,
        playlistName: _currentPlaylistName,
      );
    } catch (e) {
      debugPrint('Error playing previous song: $e');
    }
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }

  void _onSongComplete() {
    if (_isRepeatEnabled) {
      // Repeat current song
      if (_currentSong != null && _playlist.isNotEmpty) {
        playSong(
          _currentSong!,
          playlist: _playlist,
          index: _currentIndex,
          playlistName: _currentPlaylistName,
        );
      }
    } else {
      // Play next song if playlist is not empty
      if (_playlist.isNotEmpty) {
        nextSong();
      }
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentPosition = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

