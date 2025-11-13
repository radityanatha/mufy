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

  // Set timeout untuk response (15 menit untuk video panjang)
  req.setTimeout(15 * 60 * 1000);
  res.setTimeout(15 * 60 * 1000);

  try {
    // Generate unique filename
    const timestamp = Date.now();
    const outputPath = path.join(tempDir, `audio_${timestamp}.${format}`);
    const tempOutputPath = path.join(tempDir, `audio_${timestamp}.%(ext)s`);

    console.log(`[${new Date().toISOString()}] Downloading and converting: ${url}`);
    console.log(`[${new Date().toISOString()}] Output path: ${tempOutputPath}`);

    // Download dan convert menggunakan yt-dlp dengan timeout
    // Timeout 10 menit untuk proses download dan convert
    const command = `yt-dlp -x --audio-format ${format} --audio-quality 192K -o "${tempOutputPath}" "${url}"`;
    
    // Flag untuk cek apakah response sudah dikirim
    let responseSent = false;

    // Timeout untuk proses yt-dlp (10 menit)
    const processTimeout = setTimeout(() => {
      if (!responseSent) {
        responseSent = true;
        console.error(`[${new Date().toISOString()}] Timeout: Process took too long`);
        return res.status(500).json({ 
          error: 'Conversion timeout', 
          details: 'Process took longer than 10 minutes. Video might be too long or connection is slow.' 
        });
      }
    }, 10 * 60 * 1000); // 10 menit

    const childProcess = exec(command, { 
      maxBuffer: 10 * 1024 * 1024, // 10MB buffer untuk stdout/stderr
      timeout: 10 * 60 * 1000 // 10 menit timeout
    }, (error, stdout, stderr) => {
      clearTimeout(processTimeout);

      if (responseSent) {
        return; // Response sudah dikirim, jangan kirim lagi
      }

      if (error) {
        responseSent = true;
        console.error(`[${new Date().toISOString()}] Error: ${error.message}`);
        console.error(`[${new Date().toISOString()}] stderr: ${stderr}`);
        
        // Cek apakah ini error karena timeout
        if (error.signal === 'SIGTERM' || error.killed) {
          return res.status(500).json({ 
            error: 'Conversion timeout', 
            details: 'yt-dlp process was terminated due to timeout. Video might be too long.' 
          });
        }
        
        return res.status(500).json({ 
          error: 'Conversion failed', 
          details: error.message,
          stderr: stderr ? stderr.substring(0, 500) : undefined // Limit stderr length
        });
      }

      console.log(`[${new Date().toISOString()}] Conversion completed`);
      if (stdout) {
        console.log(`[${new Date().toISOString()}] stdout: ${stdout.substring(0, 200)}`);
      }

      // Tunggu sebentar untuk memastikan file sudah ditulis
      setTimeout(() => {
        try {
          // Cari file yang sudah di-generate
          const files = fs.readdirSync(tempDir);
          const generatedFile = files.find(file => file.startsWith(`audio_${timestamp}`));

          if (!generatedFile) {
            if (!responseSent) {
              responseSent = true;
              console.error(`[${new Date().toISOString()}] File not found after conversion`);
              return res.status(500).json({ 
                error: 'File not found after conversion',
                details: 'Conversion completed but output file was not found. Check temp directory permissions.'
              });
            }
            return;
          }

          const filePath = path.join(tempDir, generatedFile);
          
          // Cek apakah file ada dan tidak kosong
          const stats = fs.statSync(filePath);
          if (stats.size === 0) {
            if (!responseSent) {
              responseSent = true;
              return res.status(500).json({ 
                error: 'Empty file generated',
                details: 'Conversion completed but output file is empty.'
              });
            }
            return;
          }

          console.log(`[${new Date().toISOString()}] File found: ${generatedFile} (${(stats.size / 1024 / 1024).toFixed(2)} MB)`);

          if (responseSent) {
            return; // Response sudah dikirim
          }
          responseSent = true;

          // Set headers untuk download
          res.setHeader('Content-Type', 'audio/mpeg');
          res.setHeader('Content-Disposition', `attachment; filename="${generatedFile}"`);
          res.setHeader('Content-Length', stats.size);

          // Kirim file
          const fileStream = fs.createReadStream(filePath);
          
          fileStream.on('error', (streamError) => {
            console.error(`[${new Date().toISOString()}] Stream error: ${streamError.message}`);
            if (!res.headersSent) {
              res.status(500).json({ error: 'Error reading file', details: streamError.message });
            }
          });

          fileStream.pipe(res);

          // Hapus file setelah dikirim
          res.on('finish', () => {
            setTimeout(() => {
              if (fs.existsSync(filePath)) {
                try {
                  fs.unlinkSync(filePath);
                  console.log(`[${new Date().toISOString()}] Temp file deleted: ${generatedFile}`);
                } catch (deleteError) {
                  console.error(`[${new Date().toISOString()}] Error deleting temp file: ${deleteError.message}`);
                }
              }
            }, 5000); // Hapus setelah 5 detik
          });
        } catch (fileError) {
          if (!responseSent) {
            responseSent = true;
            console.error(`[${new Date().toISOString()}] File error: ${fileError.message}`);
            return res.status(500).json({ 
              error: 'File processing error', 
              details: fileError.message 
            });
          }
        }
      }, 1000); // Tunggu 1 detik untuk memastikan file sudah ditulis
    });

    // Handle process events
    childProcess.on('error', (processError) => {
      clearTimeout(processTimeout);
      if (!responseSent) {
        responseSent = true;
        console.error(`[${new Date().toISOString()}] Process error: ${processError.message}`);
        return res.status(500).json({ 
          error: 'Failed to start conversion process', 
          details: processError.message 
        });
      }
    });

    // Log progress jika ada
    if (childProcess.stdout) {
      childProcess.stdout.on('data', (data) => {
        const output = data.toString();
        if (output.includes('[download]') || output.includes('[ExtractAudio]')) {
          console.log(`[${new Date().toISOString()}] Progress: ${output.substring(0, 100).trim()}`);
        }
      });
    }

    if (childProcess.stderr) {
      childProcess.stderr.on('data', (data) => {
        const output = data.toString();
        // Log warning/info, bukan error (error sudah di-handle di callback)
        if (!output.toLowerCase().includes('error')) {
          console.log(`[${new Date().toISOString()}] Info: ${output.substring(0, 100).trim()}`);
        }
      });
    }

  } catch (error) {
    console.error(`[${new Date().toISOString()}] Error: ${error.message}`);
    if (!res.headersSent) {
      res.status(500).json({ error: error.message });
    }
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

