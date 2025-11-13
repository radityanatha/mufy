import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/downloaded_song.dart';
import '../services/storage_service.dart';
import 'dart:developer' as developer;

class PlaylistProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      _playlists = await _storageService.getPlaylists();
      notifyListeners();
    } catch (e) {
      developer.log('Error loading playlists: $e');
    }
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      songIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storageService.addPlaylist(playlist);
    await _loadPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      if (!playlist.songIds.contains(songId)) {
        final updatedPlaylist = Playlist(
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          coverImage: playlist.coverImage,
          songIds: [...playlist.songIds, songId],
          createdAt: playlist.createdAt,
          updatedAt: DateTime.now(),
        );

        await _storageService.updatePlaylist(updatedPlaylist);
        await _loadPlaylists();
        developer.log('Song $songId added to playlist $playlistId');
      } else {
        developer.log('Song $songId already in playlist $playlistId');
      }
    } catch (e) {
      developer.log('Error adding song to playlist: $e');
      rethrow;
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    final updatedSongIds = playlist.songIds.where((id) => id != songId).toList();

    final updatedPlaylist = Playlist(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      coverImage: playlist.coverImage,
      songIds: updatedSongIds,
      createdAt: playlist.createdAt,
      updatedAt: DateTime.now(),
    );

    await _storageService.updatePlaylist(updatedPlaylist);
    await _loadPlaylists();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _storageService.deletePlaylist(playlistId);
    await _loadPlaylists();
  }

  List<DownloadedSong> getSongsInPlaylist(
    String playlistId,
    List<DownloadedSong> allSongs,
  ) {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      return allSongs.where((song) => playlist.songIds.contains(song.id)).toList();
    } catch (e) {
      developer.log('Error getting songs in playlist: $e');
      return [];
    }
  }
}

