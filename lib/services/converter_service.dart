import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import '../models/audio_quality.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class ConverterService {
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio();

  static const String _vercelApiUrl =
      'https://mufy-api-xyz.vercel.app/api/download';

  // Download audio menggunakan Vercel Serverless Function
  // Vercel API akan download dan convert menggunakan @distube/ytdl-core
  // Hasil dikembalikan sebagai base64, lalu di-decode dan disimpan ke device
  Future<String> downloadAndConvertToMp3({
    required String videoId,
    required String title,
    required String videoUrl,
    AudioQuality quality = AudioQuality.medium,
    Function(double)? onProgress,
  }) async {
    // Check jika URL Vercel belum dikonfigurasi
    if (_vercelApiUrl.contains('YOUR_VERCEL_API_URL_HERE')) {
      throw Exception(
        '❌ Vercel API URL belum dikonfigurasi!\n\n'
        'Silakan update _vercelApiUrl di lib/services/converter_service.dart\n'
        'dengan URL Vercel Anda setelah deploy.\n\n'
        'Contoh: https://mufy-api.vercel.app/api/download',
      );
    }

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        developer.log(
          'Memulai download melalui Vercel API (Attempt ${retryCount + 1}/$maxRetries)',
        );
        developer.log('Video URL: $videoUrl');
        developer.log('Video ID: $videoId');
        developer.log('Title: $title');
        developer.log('Quality: ${quality.label}');

        if (onProgress != null) {
          onProgress(0.1); // 10% - Started
        }

        // Map quality ke format yang dimengerti Vercel API
        String qualityParam;
        switch (quality) {
          case AudioQuality.low:
            qualityParam = '96K';
            break;
          case AudioQuality.medium:
            qualityParam = '192K';
            break;
          case AudioQuality.high:
            qualityParam = '256K';
            break;
          case AudioQuality.best:
            qualityParam = '320K';
            break;
        }

        if (onProgress != null) {
          onProgress(0.2); // 20% - Processing di server
        }

        developer.log('Memanggil Vercel API: $_vercelApiUrl');

        // Panggil Vercel API
        final response = await _dio
            .post(
              _vercelApiUrl,
              data: {'videoUrl': videoUrl, 'quality': qualityParam},
              options: Options(
                responseType: ResponseType.json,
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
                headers: {'Content-Type': 'application/json'},
              ),
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw Exception('Timeout saat memanggil Vercel API');
              },
            );

        if (response.statusCode != 200 || response.data == null) {
          throw Exception(
            'Vercel API mengembalikan error: ${response.statusCode}\n'
            'Response: ${response.data}',
          );
        }

        final data = response.data;
        if (data['success'] != true || data['audio'] == null) {
          throw Exception(
            'Vercel API tidak mengembalikan audio: ${data['error'] ?? 'Unknown error'}',
          );
        }

        developer.log(
          'Audio diterima dari Vercel, ukuran: ${data['size'] ?? 'unknown'} bytes',
        );

        if (onProgress != null) {
          onProgress(0.7); // 70% - Audio received
        }

        // Decode base64 audio
        final audioBytes = base64Decode(data['audio'] as String);

        if (audioBytes.isEmpty) {
          throw Exception('Audio yang diterima kosong');
        }

        developer.log(
          'Audio decoded, ukuran: ${_formatBytes(audioBytes.length)}',
        );

        if (onProgress != null) {
          onProgress(0.9); // 90% - Decode selesai
        }

        // Simpan file ke local storage
        final extension = data['format'] ?? 'm4a';
        final localFileName = '${_sanitizeFileName(title)}_$videoId.$extension';

        developer.log('Menyimpan file ke local storage: $localFileName');

        final filePath = await _storageService.saveAudioFile(
          localFileName,
          audioBytes,
        );

        if (onProgress != null) {
          onProgress(1.0); // 100% - Selesai
        }

        developer.log('File berhasil disimpan di: $filePath');
        return filePath;
      } catch (e, stackTrace) {
        developer.log('Error: $e');
        developer.log('Stack trace: $stackTrace');

        // Handle specific error dari Vercel API
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          final errorData = e.response?.data;

          if (statusCode == 400 || statusCode == 404) {
            // Video tidak tersedia atau URL invalid
            throw Exception(
              'Video tidak tersedia atau diblokir.\n\n'
              'Kemungkinan penyebab:\n'
              '• Video dihapus atau tidak tersedia\n'
              '• Video bersifat private\n'
              '• Video diblokir di wilayah Anda\n'
              '• URL video tidak valid\n\n'
              'Error: ${errorData?['error'] ?? e.message}',
            );
          }

          if (statusCode == 500) {
            // Server error, coba retry
            retryCount++;
            if (retryCount < maxRetries) {
              developer.log(
                'Server error, retry attempt $retryCount/$maxRetries: $e',
              );
              await Future.delayed(Duration(seconds: 2 * retryCount));
              continue;
            }
          }
        }

        // Retry logic untuk connection errors
        if ((e.toString().contains('Timeout') ||
                e.toString().contains('Connection') ||
                e.toString().contains('SocketException') ||
                e.toString().contains('Network')) &&
            retryCount < maxRetries) {
          retryCount++;
          developer.log(
            'Connection error, retry attempt $retryCount/$maxRetries: $e',
          );
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }

        // Jika semua retry gagal atau error tidak bisa di-retry
        if (retryCount >= maxRetries) {
          throw Exception(
            '❌ Gagal mengunduh setelah $maxRetries percobaan.\n\n'
            'Error: $e\n\n'
            'Pastikan:\n'
            '• Vercel API sudah di-deploy\n'
            '• URL API sudah benar di converter_service.dart\n'
            '• Koneksi internet stabil',
          );
        }

        throw Exception(
          '❌ Terjadi error saat mengunduh file.\n\n'
          'Error: $e\n\n'
          'Pastikan:\n'
          '• Vercel API sudah di-deploy\n'
          '• URL API sudah benar\n'
          '• Koneksi internet stabil\n'
          '• Video URL valid',
        );
      }
    }

    // Jika semua retry gagal
    throw Exception(
      'Gagal mengunduh setelah $maxRetries percobaan.\n\n'
      'Silakan coba lagi nanti atau pastikan Vercel API sudah di-deploy.',
    );
  }

  void dispose() {
    // No cleanup needed for Vercel API
  }

  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
