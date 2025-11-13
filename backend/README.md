# Backend Server untuk Mufy

Backend server untuk melakukan konversi YouTube ke MP3 menggunakan yt-dlp.

## Persyaratan

1. **Node.js** (v14 atau lebih baru)
2. **yt-dlp** - Install via pip:
   ```bash
   pip install yt-dlp
   ```
3. **ffmpeg** - Required untuk konversi audio
   - Windows: Download dari https://ffmpeg.org/download.html
   - Linux: `sudo apt install ffmpeg`
   - macOS: `brew install ffmpeg`

## Install dan Setup

1. Install dependencies:
```bash
npm install
```

2. Pastikan yt-dlp dan ffmpeg sudah terinstall:
```bash
yt-dlp --version
ffmpeg -version
```

3. Jalankan server:
```bash
npm start
```

Server akan berjalan di `http://localhost:3000`

## Endpoints

### GET /api/download

Download dan convert YouTube video ke MP3.

**Parameters:**
- `url` (required): URL YouTube video
- `format` (optional): Format audio (default: mp3)

**Example:**
```
http://localhost:3000/api/download?url=https://youtube.com/watch?v=VIDEO_ID&format=mp3
```

### GET /health

Health check endpoint.

**Example:**
```
http://localhost:3000/health
```

## Konfigurasi untuk Android

Untuk Android, Anda perlu menggunakan IP address komputer Anda, bukan localhost.

1. Cari IP address komputer Anda:
   - Windows: `ipconfig`
   - Linux/macOS: `ifconfig` atau `ip addr`

2. Update URL di `lib/services/converter_service.dart`:
```dart
final backendUrl = 'http://YOUR_IP_ADDRESS:3000/api/download';
```

3. Pastikan firewall mengizinkan koneksi pada port 3000.

## Troubleshooting

### Error: yt-dlp tidak ditemukan

Pastikan yt-dlp sudah terinstall dan ada di PATH:
```bash
pip install yt-dlp
```

### Error: ffmpeg tidak ditemukan

Install ffmpeg sesuai dengan sistem operasi Anda.

### Error: Port sudah digunakan

Ubah PORT di `server.js` atau hentikan aplikasi yang menggunakan port 3000.

### Android tidak bisa connect ke backend

1. Pastikan Android dan komputer berada di jaringan WiFi yang sama
2. Gunakan IP address, bukan localhost
3. Pastikan firewall mengizinkan koneksi

