enum AudioQuality {
  low,     // ~64-128 kbps - File kecil, download cepat
  medium,  // ~128-192 kbps - Keseimbangan (default)
  high,    // ~192-256 kbps - Kualitas bagus
  best,    // Tertinggi - Kualitas terbaik, file besar
}

extension AudioQualityExtension on AudioQuality {
  String get label {
    switch (this) {
      case AudioQuality.low:
        return 'Rendah (~64-128 kbps) - Cepat';
      case AudioQuality.medium:
        return 'Sedang (~128-192 kbps) - Seimbang';
      case AudioQuality.high:
        return 'Tinggi (~192-256 kbps) - Bagus';
      case AudioQuality.best:
        return 'Terbaik - Kualitas Tertinggi';
    }
  }

  String get shortLabel {
    switch (this) {
      case AudioQuality.low:
        return 'Rendah';
      case AudioQuality.medium:
        return 'Sedang';
      case AudioQuality.high:
        return 'Tinggi';
      case AudioQuality.best:
        return 'Terbaik';
    }
  }

  String get description {
    switch (this) {
      case AudioQuality.low:
        return 'File kecil, download cepat, kualitas cukup';
      case AudioQuality.medium:
        return 'Keseimbangan antara kualitas dan ukuran file';
      case AudioQuality.high:
        return 'Kualitas bagus, ukuran file sedang';
      case AudioQuality.best:
        return 'Kualitas terbaik, file besar, download lambat';
    }
  }
}

