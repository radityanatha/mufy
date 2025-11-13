import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_song.dart';

class StorageService {
  static const String _songsKey = 'downloaded_songs';

  // Get aplikasi documents directory
  Future<Directory> getMusicDirectory() async {
    if (Platform.isAndroid) {
      // Android: simpan di aplikasi documents
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/Music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir;
    } else {
      // Desktop: simpan di documents/MufyMusic
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/MufyMusic');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir;
    }
  }

  // Simpan file MP3
  Future<String> saveMp3File(String fileName, List<int> bytes) async {
    final musicDir = await getMusicDirectory();
    final file = File('${musicDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // Hapus file MP3
  Future<bool> deleteMp3File(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Simpan daftar lagu ke SharedPreferences
  Future<void> saveDownloadedSongs(List<DownloadedSong> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = songs.map((song) => jsonEncode(song.toJson())).toList();
    await prefs.setStringList(_songsKey, songsJson);
  }

  // Ambil daftar lagu dari SharedPreferences
  Future<List<DownloadedSong>> getDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final songsJson = prefs.getStringList(_songsKey) ?? [];
    return songsJson
        .map((json) => DownloadedSong.fromJson(jsonDecode(json)))
        .toList();
  }

  // Tambah lagu ke daftar
  Future<void> addDownloadedSong(DownloadedSong song) async {
    final songs = await getDownloadedSongs();
    songs.add(song);
    await saveDownloadedSongs(songs);
  }

  // Hapus lagu dari daftar
  Future<void> removeDownloadedSong(String id) async {
    final songs = await getDownloadedSongs();
    songs.removeWhere((song) => song.id == id);
    await saveDownloadedSongs(songs);
  }

  // Cek apakah file masih ada
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }
}

