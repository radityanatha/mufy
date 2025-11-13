# Panduan Deploy Vercel untuk Mufy

Panduan lengkap untuk deploy Vercel API dan setup Flutter app.

## 📋 Prerequisites

1. Akun Vercel (gratis di [vercel.com](https://vercel.com))
2. Node.js dan npm terinstall
3. Vercel CLI (opsional, untuk deploy via command line)

## 🚀 Step 1: Deploy Vercel API

### Opsi A: Deploy via Vercel CLI (Recommended)

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Login ke Vercel:
```bash
vercel login
```

3. Masuk ke folder `vercel`:
```bash
cd vercel
```

4. Install dependencies:
```bash
npm install
```

5. Deploy ke preview:
```bash
vercel
```

6. Deploy ke production:
```bash
vercel --prod
```

7. **Catat URL yang diberikan!** (contoh: `https://mufy-api.vercel.app`)

### Opsi B: Deploy via Vercel Dashboard

1. Buka [vercel.com](https://vercel.com) dan login
2. Klik "Add New..." → "Project"
3. Import dari GitHub (jika project sudah di GitHub) atau:
   - Klik "Browse" dan pilih folder `vercel/`
   - Atau drag & drop folder `vercel/`
4. Set konfigurasi:
   - **Framework Preset**: Other
   - **Root Directory**: `vercel` (jika import dari root project)
   - **Build Command**: (kosongkan)
   - **Output Directory**: (kosongkan)
5. Klik "Deploy"
6. **Catat URL yang diberikan!** (contoh: `https://mufy-api.vercel.app`)

## 🔧 Step 2: Update Flutter App

1. Buka file `lib/services/converter_service.dart`

2. Cari baris ini (sekitar line 13):
```dart
static const String _vercelApiUrl = 'YOUR_VERCEL_API_URL_HERE/api/download';
```

3. Ganti `YOUR_VERCEL_API_URL_HERE` dengan URL Vercel Anda:
```dart
static const String _vercelApiUrl = 'https://mufy-api.vercel.app/api/download';
```

4. Simpan file

## ✅ Step 3: Test Aplikasi

1. Jalankan aplikasi Flutter:
```bash
flutter run
```

2. Coba download video YouTube
3. Check log jika ada error

## 📱 Step 4: Build APK (untuk Android)

Setelah Vercel API berhasil, build APK untuk distribusi:

```bash
flutter build apk --release
```

APK akan ada di: `build/app/outputs/flutter-apk/app-release.apk`

## 🔍 Troubleshooting

### Error: "Vercel API URL belum dikonfigurasi"
- Pastikan sudah update `_vercelApiUrl` di `converter_service.dart`
- Pastikan URL format benar: `https://your-project.vercel.app/api/download`

### Error: "Timeout saat memanggil Vercel API"
- Vercel free tier: timeout 10 detik
- Vercel Pro: timeout 60 detik
- Untuk video panjang, pertimbangkan upgrade ke Pro plan

### Error: "Video tidak tersedia atau diblokir"
- Video mungkin private atau dihapus
- Coba dengan video YouTube lain
- Library `@distube/ytdl-core` bisa terblokir YouTube

### Error: "Module not found" di Vercel
- Pastikan `npm install` sudah dijalankan di folder `vercel`
- Pastikan `package.json` sudah benar

### Error: "Function timeout"
- Video terlalu panjang untuk timeout yang tersedia
- Upgrade ke Vercel Pro untuk timeout 60 detik
- Atau gunakan video yang lebih pendek

## 📝 Catatan Penting

1. **Timeout**: 
   - Free tier: 10 detik
   - Pro plan: 60 detik
   - Untuk video panjang, upgrade ke Pro

2. **Library**: 
   - Menggunakan `@distube/ytdl-core`
   - Bisa terblokir YouTube, jika terjadi coba library alternatif

3. **CORS**: 
   - Sudah dikonfigurasi di `vercel.json`
   - Tidak perlu setup tambahan

4. **Biaya**:
   - Free tier: 100GB-hours/bulan
   - Pro plan: $20/bulan (unlimited)

## 🎯 Checklist Deploy

- [ ] Vercel API sudah di-deploy
- [ ] URL Vercel sudah dicatat
- [ ] `_vercelApiUrl` di `converter_service.dart` sudah di-update
- [ ] Test download berhasil
- [ ] Build APK untuk distribusi

## 📚 Referensi

- [Vercel Documentation](https://vercel.com/docs)
- [Vercel Serverless Functions](https://vercel.com/docs/functions)
- [@distube/ytdl-core](https://www.npmjs.com/package/@distube/ytdl-core)

