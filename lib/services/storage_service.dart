import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../models/downloaded_song.dart';

class StorageService {
  static const String _songsKey = 'downloaded_songs';

  // Request permission untuk akses storage
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // Android 13+ (API 33+): Request audio permission
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) {
        developer.log('Audio permission already granted');
        return true;
      }

      // Android 10-12: Request storage permission
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        developer.log('Storage permission already granted');
        return true;
      }

      // Jika permanently denied, tidak bisa request lagi (perlu buka Settings)
      if (storageStatus.isPermanentlyDenied) {
        developer.log(
          'Storage permission permanently denied - need to open Settings',
        );
        return false;
      }

      if (audioStatus.isPermanentlyDenied) {
        developer.log(
          'Audio permission permanently denied - need to open Settings',
        );
        return false;
      }

      // Request storage permission untuk Android 10-12
      if (!storageStatus.isGranted && !storageStatus.isPermanentlyDenied) {
        final requestedStorageStatus = await Permission.storage.request();
        if (requestedStorageStatus.isGranted) {
          developer.log('Storage permission granted');
          return true;
        }
        if (requestedStorageStatus.isPermanentlyDenied) {
          developer.log('Storage permission permanently denied');
          return false;
        }
      }

      // Jika storage permission tidak diberikan, coba audio permission (Android 13+)
      if (!audioStatus.isGranted && !audioStatus.isPermanentlyDenied) {
        final requestedAudioStatus = await Permission.audio.request();
        if (requestedAudioStatus.isGranted) {
          developer.log('Audio permission granted');
          return true;
        }
        if (requestedAudioStatus.isPermanentlyDenied) {
          developer.log('Audio permission permanently denied');
          return false;
        }
      }

      developer.log('Storage permission denied');
      return false;
    } catch (e) {
      developer.log('Error requesting permission: $e');
      return false;
    }
  }

  // Cek apakah permission permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;

    try {
      final storageStatus = await Permission.storage.status;
      final audioStatus = await Permission.audio.status;
      return storageStatus.isPermanentlyDenied ||
          audioStatus.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  // Buka Settings untuk memberikan permission manual
  // Catatan: Gunakan openAppSettings() dari package permission_handler secara langsung
  // Contoh: await openAppSettings();

  // Get Music directory publik
  Future<Directory> getMusicDirectory() async {
    if (Platform.isAndroid) {
      // Request permission dulu
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
          'Permission storage tidak diberikan.\n\n'
          'File tidak bisa disimpan ke folder Music publik.\n'
          'Silakan berikan permission storage di pengaturan aplikasi.',
        );
      }

      try {
        // Gunakan external storage directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Extract root path dari external storage
          // Path biasanya: /storage/emulated/0/Android/data/com.example.mufy/files
          // Kita ingin: /storage/emulated/0/Music/Mufy
          final externalStoragePath = directory.path;

          // Extract root path (hapus /Android/data/...)
          String rootPath;
          if (externalStoragePath.contains('/Android/data/')) {
            rootPath = externalStoragePath.split('/Android/data/')[0];
          } else if (externalStoragePath.contains('/Android/')) {
            rootPath = externalStoragePath.split('/Android/')[0];
          } else {
            // Fallback: coba gunakan path langsung
            rootPath = '/storage/emulated/0';
          }

          final musicDir = Directory('$rootPath/Music/Mufy');
          developer.log('Music directory: ${musicDir.path}');

          if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
            developer.log('Created music directory: ${musicDir.path}');
          }
          return musicDir;
        }
      } catch (e) {
        developer.log('Error accessing external storage: $e');
        // Fallback ke internal storage jika external tidak tersedia
      }

      // Fallback: gunakan internal storage (jika external tidak tersedia)
      developer.log('Using fallback: internal storage');
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/Music');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir;
    } else if (Platform.isWindows) {
      // Windows: Simpan di Music folder user
      final userProfile = Platform.environment['USERPROFILE'] ?? '';
      if (userProfile.isNotEmpty) {
        final musicDir = Directory('$userProfile/Music/Mufy');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        developer.log('Windows Music directory: ${musicDir.path}');
        return musicDir;
      }
      // Fallback ke Documents
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/MufyMusic');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir;
    } else if (Platform.isLinux || Platform.isMacOS) {
      // Linux/Mac: Simpan di Music folder user
      final userHome = Platform.environment['HOME'] ?? '';
      if (userHome.isNotEmpty) {
        final musicDir = Directory('$userHome/Music/Mufy');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        developer.log('Linux/Mac Music directory: ${musicDir.path}');
        return musicDir;
      }
      // Fallback ke Documents
      final directory = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${directory.path}/MufyMusic');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      return musicDir;
    } else {
      // Default: Documents
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

    developer.log('File saved to: ${file.path}');
    developer.log('File size: ${_formatBytes(bytes.length)}');

    // Untuk Android, scan file ke MediaStore agar muncul di aplikasi musik
    if (Platform.isAndroid) {
      try {
        // Gunakan method channel untuk scan file ke MediaStore
        // Method channel native Android untuk scan file
        const platform = MethodChannel('com.example.mufy/media_scanner');
        await platform.invokeMethod('scanFile', {'path': file.path});
        developer.log('File scanned to MediaStore: ${file.path}');
        developer.log(
          'File akan muncul di aplikasi musik dalam beberapa detik',
        );
      } catch (e) {
        developer.log('Error scanning file to MediaStore: $e');
        developer.log('File tetap tersimpan di: ${file.path}');
        developer.log(
          'File akan muncul di aplikasi musik setelah restart aplikasi musik atau device',
        );
        // File tetap tersimpan, hanya tidak terdeteksi oleh MediaStore
        // User bisa restart aplikasi musik atau device untuk trigger media scan
        // Atau file akan terdeteksi secara otomatis oleh MediaStore setelah beberapa saat
      }
    }

    return file.path;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
