# Vercel API untuk Mufy

Serverless Function untuk download YouTube audio menggunakan Vercel.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Test lokal (opsional):
```bash
npm run dev
```

3. Deploy ke Vercel:
```bash
# Login ke Vercel (pertama kali)
vercel login

# Deploy ke preview
vercel

# Deploy ke production
vercel --prod
```

4. Catat URL yang diberikan (contoh: `https://mufy-api.vercel.app`)

5. Update URL di Flutter app:
   - Buka `lib/services/converter_service.dart`
   - Ganti `YOUR_VERCEL_API_URL_HERE` dengan URL Vercel Anda
   - Contoh: `static const String _vercelApiUrl = 'https://mufy-api.vercel.app/api/download';`

## Deploy via Vercel Dashboard

1. Buka [vercel.com](https://vercel.com)
2. Import project dari GitHub (atau upload folder `vercel/`)
3. Set root directory ke `vercel`
4. Deploy otomatis

## Catatan

- Timeout maksimal: 60 detik (Pro plan) atau 10 detik (Hobby plan)
- Untuk video panjang, pertimbangkan upgrade ke Pro plan
- Library `@distube/ytdl-core` bisa terblokir YouTube, jika terjadi coba library alternatif

