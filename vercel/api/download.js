// Vercel Serverless Function untuk download YouTube audio
// Menggunakan @distube/ytdl-core (library JavaScript)

const ytdl = require('@distube/ytdl-core');
const { Readable } = require('stream');

// Helper untuk convert stream ke buffer
function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('end', () => resolve(Buffer.concat(chunks)));
    stream.on('error', reject);
  });
}

export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { videoUrl, quality = '192K' } = req.body;

    if (!videoUrl) {
      return res.status(400).json({ error: 'Video URL is required' });
    }

    console.log(`Starting download for: ${videoUrl}`);
    console.log(`Quality: ${quality}`);

    // Validate YouTube URL
    if (!ytdl.validateURL(videoUrl)) {
      return res.status(400).json({ error: 'Invalid YouTube URL' });
    }

    // Get video info
    const info = await ytdl.getInfo(videoUrl);
    console.log(`Video title: ${info.videoDetails.title}`);

    // Map quality parameter ke format ytdl
    let formatFilter = 'highestaudio';
    if (quality === '96K') {
      formatFilter = 'lowestaudio';
    } else if (quality === '192K') {
      formatFilter = 'highestaudio';
    } else if (quality === '256K' || quality === '320K') {
      formatFilter = 'highestaudio';
    }

    // Download audio stream
    const audioStream = ytdl(videoUrl, {
      quality: formatFilter,
      filter: 'audioonly',
    });

    // Convert stream to buffer
    const audioBuffer = await streamToBuffer(audioStream);

    if (!audioBuffer || audioBuffer.length === 0) {
      throw new Error('Downloaded audio is empty');
    }

    console.log(`Downloaded audio size: ${audioBuffer.length} bytes`);

    // Return audio as base64
    const base64Audio = audioBuffer.toString('base64');

    return res.status(200).json({
      success: true,
      audio: base64Audio,
      format: 'm4a', // ytdl biasanya return m4a
      size: audioBuffer.length,
      title: info.videoDetails.title,
    });
  } catch (error) {
    console.error('Error:', error);

    // Handle specific errors
    if (error.message.includes('Video unavailable')) {
      return res.status(404).json({
        error: 'Video tidak tersedia atau diblokir',
        details: error.message,
      });
    }

    if (error.message.includes('Private video')) {
      return res.status(403).json({
        error: 'Video bersifat private',
        details: error.message,
      });
    }

    return res.status(500).json({
      error: 'Gagal memproses video',
      details: error.message,
    });
  }
}

