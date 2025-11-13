import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import 'dart:developer' as developer;

class ConverterService {
  final StorageService _storageService = StorageService();
  final Dio _dio = Dio();

  // Download dan convert YouTube ke MP3 menggunakan API pihak ketiga
  // CATATAN: Untuk production, buat backend sendiri atau gunakan API yang legal
  Future<String> downloadAndConvertToMp3({
    required String videoId,
    required String title,
    required String videoUrl,
    Function(double)? onProgress,
  }) async {
    try {
      // Menggunakan backend server sendiri (disarankan)
      // Setup backend server dengan yt-dlp (lihat folder backend/)
      //
      // Untuk Android: Gunakan IP address komputer, bukan localhost
      // Contoh: http://192.168.1.100:3000/api/download
      //
      // Untuk Desktop: Bisa menggunakan localhost
      // Contoh: http://localhost:3000/api/download

      // Konfigurasi URL backend
      // Untuk development: http://localhost:3000/api/download
      // Untuk production: Ganti dengan URL server production Anda
      final backendUrl = 'http://localhost:3000/api/download';

      // Jika backend tidak tersedia, gunakan alternatif
      // Anda bisa menggunakan service seperti:
      // - Membuat backend sendiri dengan yt-dlp
      // - Menggunakan API converter yang legal

      try {
        developer.log('Memulai download dari: $backendUrl');
        developer.log('Video URL: $videoUrl');
        developer.log('Video ID: $videoId');
        developer.log('Title: $title');

        final response = await _dio.get(
          backendUrl,
          queryParameters: {'url': videoUrl, 'format': 'mp3'},
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveTimeout: const Duration(minutes: 10), // Timeout 10 menit untuk download besar
            sendTimeout: const Duration(seconds: 30),
          ),
          onReceiveProgress: (received, total) {
            if (total > 0 && onProgress != null) {
              final progressPercent = received / total;
              onProgress(progressPercent);
              if (received % 100000 == 0 || received == total) {
                // Log setiap 100KB atau saat selesai
                developer.log(
                  'Download progress: ${(progressPercent * 100).toStringAsFixed(1)}% '
                  '(${_formatBytes(received)} / ${_formatBytes(total)})',
                );
              }
            }
          },
        );

        if (response.data == null || response.data.isEmpty) {
          developer.log('Error: Response data kosong');
          throw Exception('File yang diterima kosong. Pastikan backend server berfungsi dengan baik.');
        }

        developer.log('Download selesai, ukuran file: ${_formatBytes(response.data.length)}');

        // Simpan file ke local storage
        final fileName = '${_sanitizeFileName(title)}_$videoId.mp3';
        developer.log('Menyimpan file: $fileName');
        
        final filePath = await _storageService.saveMp3File(
          fileName,
          response.data,
        );

        developer.log('File berhasil disimpan di: $filePath');
        return filePath;
      } on DioException catch (e) {
        // Handle error spesifik dari Dio
        String errorMessage = 'Gagal mengunduh file';
        
        developer.log('DioException terjadi: ${e.type}');
        developer.log('Error message: ${e.message}');
        developer.log('Error response: ${e.response?.data}');
        developer.log('Error status code: ${e.response?.statusCode}');

        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = '⏱️ Timeout: Koneksi ke server terlalu lama.\n\n'
              'Kemungkinan penyebab:\n'
              '• Video terlalu panjang\n'
              '• Koneksi internet lambat\n'
              '• Backend server tidak merespons\n\n'
              'Pastikan backend server berjalan di: $backendUrl';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = '🔌 Tidak dapat terhubung ke server.\n\n'
              'Pastikan:\n'
              '• Backend server sudah berjalan\n'
              '• URL backend benar: $backendUrl\n'
              '• Untuk Android emulator, gunakan IP komputer (bukan localhost)\n'
              '• Firewall tidak memblokir koneksi';
        } else if (e.response != null) {
          // Server mengembalikan error response
          final statusCode = e.response!.statusCode;
          final errorData = e.response!.data;
          
          String errorDetail = '';
          if (errorData is Map) {
            errorDetail = errorData['error']?.toString() ?? 
                         errorData['details']?.toString() ?? 
                         errorData.toString();
          } else if (errorData is String) {
            errorDetail = errorData;
          } else {
            errorDetail = errorData.toString();
          }
          
          errorMessage = '❌ Server error ($statusCode)\n\n'
              'Detail error:\n$errorDetail\n\n'
              'Pastikan:\n'
              '• Backend server berjalan dengan baik\n'
              '• yt-dlp terinstall dan berfungsi\n'
              '• Video URL valid dan dapat diakses';
        } else {
          errorMessage = '❌ Error: ${e.message ?? e.toString()}\n\n'
              'Pastikan backend server berjalan di: $backendUrl';
        }
        
        throw Exception(errorMessage);
      } catch (e, stackTrace) {
        developer.log('Error umum: $e');
        developer.log('Stack trace: $stackTrace');
        
        // Cek apakah ini error dari Dio yang tidak tertangkap
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Failed host lookup')) {
          throw Exception(
            '🔌 Tidak dapat terhubung ke server.\n\n'
            'Pastikan:\n'
            '• Backend server sudah berjalan di $backendUrl\n'
            '• Untuk Android emulator, gunakan IP komputer (bukan localhost)\n'
            '• Koneksi internet stabil\n\n'
            'Error detail: $e',
          );
        }
        
        throw Exception(
          '❌ Terjadi error saat mengunduh file.\n\n'
          'Error: $e\n\n'
          'Pastikan:\n'
          '• Backend server berjalan dengan baik\n'
          '• yt-dlp terinstall dan berfungsi\n'
          '• Video URL valid',
        );
      }
    } catch (e) {
      rethrow;
    }
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
