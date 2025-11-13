/**
 * Backend Server untuk YouTube to MP3 Converter
 * 
 * Persyaratan:
 * - Node.js
 * - yt-dlp (install via pip: pip install yt-dlp)
 * - ffmpeg (untuk konversi audio)
 * 
 * Install dependencies:
 * npm install express cors
 * 
 * Jalankan:
 * node server.js
 */

const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Buat folder temp jika belum ada
const tempDir = path.join(__dirname, 'temp');
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
}

// Endpoint untuk download dan convert
app.get('/api/download', (req, res) => {
  const { url, format = 'mp3' } = req.query;

  if (!url) {
    return res.status(400).json({ error: 'URL is required' });
  }

  try {
    // Generate unique filename
    const timestamp = Date.now();
    const outputPath = path.join(tempDir, `audio_${timestamp}.${format}`);
    const tempOutputPath = path.join(tempDir, `audio_${timestamp}.%(ext)s`);

    console.log(`Downloading and converting: ${url}`);

    // Download dan convert menggunakan yt-dlp
    const command = `yt-dlp -x --audio-format ${format} --audio-quality 192K -o "${tempOutputPath}" "${url}"`;

    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error: ${error.message}`);
        return res.status(500).json({ 
          error: 'Conversion failed', 
          details: error.message 
        });
      }

      // Cari file yang sudah di-generate
      const files = fs.readdirSync(tempDir);
      const generatedFile = files.find(file => file.startsWith(`audio_${timestamp}`));

      if (!generatedFile) {
        return res.status(500).json({ error: 'File not found after conversion' });
      }

      const filePath = path.join(tempDir, generatedFile);

      // Set headers untuk download
      res.setHeader('Content-Type', 'audio/mpeg');
      res.setHeader('Content-Disposition', `attachment; filename="${generatedFile}"`);

      // Kirim file
      const fileStream = fs.createReadStream(filePath);
      fileStream.pipe(res);

      // Hapus file setelah dikirim
      fileStream.on('end', () => {
        setTimeout(() => {
          if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
          }
        }, 5000); // Hapus setelah 5 detik
      });
    });
  } catch (error) {
    console.error(`Error: ${error.message}`);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Download endpoint: http://localhost:${PORT}/api/download?url=YOUTUBE_URL&format=mp3`);
});

