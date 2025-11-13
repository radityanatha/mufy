# Mufy - YouTube to MP3 Converter

Aplikasi Flutter untuk mengkonversi video YouTube menjadi file MP3. Aplikasi ini mendukung **Desktop (Windows/Linux/macOS)** dan **Android** dengan penyimpanan file di local storage aplikasi.

## Fitur

- ✅ Responsive design untuk Desktop dan Android
- ✅ Download dan konversi YouTube ke MP3
- ✅ Penyimpanan file di local storage aplikasi
- ✅ Daftar lagu yang sudah didownload
- ✅ Hapus lagu dari daftar
- ✅ UI modern dengan Material Design 3

## Persyaratan

- Flutter SDK 3.9.2 atau lebih baru
- Dart SDK 3.9.2 atau lebih baru
- Backend server untuk konversi (lihat bagian Setup Backend)

## Instalasi

1. Clone repository atau extract project
2. Install dependencies:
```bash
flutter pub get
```

3. Setup backend server (lihat bagian Setup Backend)

4. Update URL backend di `lib/services/converter_service.dart`:
```dart
final backendUrl = 'http://localhost:3000/api/download'; // Ganti dengan URL backend Anda
```

5. Jalankan aplikasi:
```bash
# Untuk Android
flutter run -d android

# Untuk Desktop (Windows)
flutter run -d windows

# Untuk Desktop (Linux)
flutter run -d linux

# Untuk Desktop (macOS)
flutter run -d macos
```

## Setup Backend

Aplikasi ini memerlukan backend server untuk melakukan konversi YouTube ke MP3. Anda memiliki beberapa opsi:

### Opsi 1: Backend dengan yt-dlp (Disarankan)

Buat backend server menggunakan Node.js atau Python dengan yt-dlp:

#### Node.js + Express + yt-dlp

```javascript
// server.js
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const app = express();

app.get('/api/download', async (req, res) => {
  const { url, format = 'mp3' } = req.query;
  
  try {
    // Download dan convert menggunakan yt-dlp
    const outputPath = path.join(__dirname, 'temp', `audio.${format}`);
    
    exec(`yt-dlp -x --audio-format ${format} -o "${outputPath}" "${url}"`, 
      (error, stdout, stderr) => {
        if (error) {
          return res.status(500).json({ error: error.message });
        }
        
        // Kirim file
        res.download(outputPath, (err) => {
          if (err) {
            res.status(500).json({ error: 'Failed to send file' });
          }
          // Hapus file temporary
          fs.unlinkSync(outputPath);
        });
      });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

#### Python + Flask + yt-dlp

```python
# server.py
from flask import Flask, send_file, request
import yt_dlp
import os
import tempfile

app = Flask(__name__)

@app.route('/api/download')
def download():
    url = request.args.get('url')
    format = request.args.get('format', 'mp3')
    
    # Setup yt-dlp options
    ydl_opts = {
        'format': 'bestaudio/best',
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': format,
            'preferredquality': '192',
        }],
        'outtmpl': '%(title)s.%(ext)s',
    }
    
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        # Download dan convert
        info = ydl.extract_info(url, download=True)
        filename = ydl.prepare_filename(info)
        filename = os.path.splitext(filename)[0] + f'.{format}'
        
        return send_file(filename, as_attachment=True)

if __name__ == '__main__':
    app.run(port=3000)
```

### Opsi 2: Menggunakan API Converter Pihak Ketiga

Anda juga bisa menggunakan API converter pihak ketiga yang legal. Update `converter_service.dart` untuk menggunakan API tersebut.

**Catatan Penting:** Pastikan API yang Anda gunakan legal dan tidak melanggar Terms of Service YouTube.

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── video_info.dart
│   └── downloaded_song.dart
├── services/                 # Business logic
│   ├── storage_service.dart  # Handle local storage
│   ├── youtube_service.dart  # Fetch YouTube metadata
│   └── converter_service.dart # Handle conversion
├── providers/                # State management
│   └── converter_provider.dart
├── screens/                  # UI screens
│   └── home_screen.dart
├── widgets/                  # Reusable widgets
│   ├── url_input_widget.dart
│   ├── video_info_card.dart
│   └── downloaded_songs_list.dart
└── utils/                    # Utilities
    └── responsive.dart       # Responsive helper
```

## Penyimpanan File

- **Android**: File disimpan di `app_documents/Music/`
- **Desktop**: File disimpan di `Documents/MufyMusic/`

File disimpan di local storage aplikasi, sehingga tidak memerlukan permission storage eksternal untuk Android 10+.

## Build untuk Production

### Android

```bash
flutter build apk --release
# atau
flutter build appbundle --release
```

### Desktop (Windows)

```bash
flutter build windows --release
```

### Desktop (Linux)

```bash
flutter build linux --release
```

### Desktop (macOS)

```bash
flutter build macos --release
```

## Troubleshooting

### Error: Backend converter belum dikonfigurasi

Pastikan:
1. Backend server sudah running
2. URL backend di `converter_service.dart` sudah benar
3. Backend bisa diakses dari aplikasi (untuk Android, gunakan IP address bukan localhost)

### Error: Gagal mengambil informasi video

Pastikan:
1. URL YouTube valid
2. Koneksi internet tersedia
3. Video tidak di-restrict atau dihapus

## Lisensi

Project ini dibuat untuk tujuan edukasi. Pastikan untuk mematuhi Terms of Service YouTube dan hukum yang berlaku.

## Catatan Legal

- Pengunduhan konten YouTube mungkin melanggar Terms of Service YouTube
- Pastikan Anda memiliki hak untuk mengunduh konten yang di-download
- Gunakan aplikasi ini dengan tanggung jawab
