import 'package:flutter/material.dart';
import '../models/video_info.dart';
import '../models/downloaded_song.dart';
import '../services/youtube_service.dart';
import '../services/converter_service.dart';
import '../services/storage_service.dart';
import 'dart:developer' as developer;

class ConverterProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final ConverterService _converterService = ConverterService();
  final StorageService _storageService = StorageService();

  VideoInfo? _videoInfo;
  bool _isLoading = false;
  String? _error;
  double _downloadProgress = 0.0;
  List<DownloadedSong> _downloadedSongs = [];

  VideoInfo? get videoInfo => _videoInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get downloadProgress => _downloadProgress;
  List<DownloadedSong> get downloadedSongs => _downloadedSongs;

  ConverterProvider() {
    _loadDownloadedSongs();
  }

  Future<void> _loadDownloadedSongs() async {
    try {
      _downloadedSongs = await _storageService.getDownloadedSongs();
      // Filter hanya file yang masih ada
      final validSongs = <DownloadedSong>[];
      for (final song in _downloadedSongs) {
        final exists = await _storageService.fileExists(song.filePath);
        if (exists) {
          validSongs.add(song);
        } else {
          await _storageService.removeDownloadedSong(song.id);
        }
      }
      _downloadedSongs = validSongs;
      notifyListeners();
    } catch (e) {
      // Ignore error saat loading
    }
  }

  Future<void> fetchVideoInfo(String url) async {
    _isLoading = true;
    _error = null;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      _videoInfo = await _youtubeService.getVideoInfo(url);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _videoInfo = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> convertToMp3() async {
    if (_videoInfo == null) return;

    _isLoading = true;
    _error = null;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // Cek apakah sudah pernah didownload
      final existingSong = _downloadedSongs
          .where((song) => song.id == _videoInfo!.id)
          .firstOrNull;

      if (existingSong != null) {
        final exists = await _storageService.fileExists(existingSong.filePath);
        if (exists) {
          _error = 'Lagu ini sudah pernah didownload';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _downloadProgress = 0.1;
      notifyListeners();

      developer.log('Memulai konversi ke MP3');
      developer.log('Video ID: ${_videoInfo!.id}');
      developer.log('Title: ${_videoInfo!.title}');

      // Download dan convert
      final videoUrl = 'https://youtube.com/watch?v=${_videoInfo!.id}';
      final filePath = await _converterService.downloadAndConvertToMp3(
        videoId: _videoInfo!.id,
        title: _videoInfo!.title,
        videoUrl: videoUrl,
        onProgress: (progress) {
          _downloadProgress = 0.1 + (progress * 0.8);
          notifyListeners();
        },
      );

      developer.log('Konversi berhasil, file path: $filePath');

      _downloadProgress = 0.9;
      notifyListeners();

      // Simpan ke daftar
      final downloadedSong = DownloadedSong(
        id: _videoInfo!.id,
        title: _videoInfo!.title,
        filePath: filePath,
        thumbnail: _videoInfo!.thumbnail,
        downloadedAt: DateTime.now(),
      );

      await _storageService.addDownloadedSong(downloadedSong);
      await _loadDownloadedSongs();

      _downloadProgress = 1.0;
      _error = null;
      developer.log('Download dan konversi selesai dengan sukses');
    } catch (e, stackTrace) {
      developer.log('Error di convertToMp3: $e');
      developer.log('Stack trace: $stackTrace');
      
      // Bersihkan error message dari prefix "Exception: "
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Jika error message terlalu panjang, potong dan tambahkan instruksi
      if (errorMessage.length > 500) {
        errorMessage = '${errorMessage.substring(0, 500)}...\n\n'
            'Lihat log untuk detail lengkap.';
      }
      
      _error = errorMessage;
      _downloadProgress = 0.0;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSong(String id) async {
    try {
      final song = _downloadedSongs.where((s) => s.id == id).firstOrNull;
      if (song != null) {
        await _storageService.deleteMp3File(song.filePath);
        await _storageService.removeDownloadedSong(id);
        await _loadDownloadedSongs();
      }
    } catch (e) {
      _error = 'Gagal menghapus lagu: $e';
      notifyListeners();
    }
  }

  void clear() {
    _videoInfo = null;
    _error = null;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _youtubeService.dispose();
    super.dispose();
  }
}

