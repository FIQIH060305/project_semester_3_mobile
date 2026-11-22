import 'dart:math' as math;

/// Model data untuk satu split kilometer
class SplitKilometer {
  final int kilometerKe;
  final Duration durasiSplit;
  final String paceFormatted;
  final bool isTercepat;

  SplitKilometer({
    required this.kilometerKe,
    required this.durasiSplit,
    required this.paceFormatted,
    this.isTercepat = false,
  });

  String get durasiFormatted {
    final m = durasiSplit.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = durasiSplit.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Helper kalkulator untuk metrik pelacakan olahraga GERAK
class TrackingCalculator {
  /// Radius bumi dalam meter untuk rumus Haversine
  static const double earthRadiusMeters = 6371000.0;

  /// Menghitung jarak antara dua koordinat GPS menggunakan rumus Haversine (meter)
  static double hitungJarakHaversine({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1Rad) *
            math.cos(lat2Rad);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Penyaringan koordinat GPS agar terhindar dari noise diam dan lompatan sinyal
  static bool isTitikValid({
    required double distanceMeters,
    required double timeSeconds,
    required double accuracyMeters,
    bool isBerlari = true,
    double maxAccuracyThreshold = 30.0, // Abaikan sinyal dengan akurasi > 30m
    double minDisplacement = 2.5, // Abaikan pergeseran mikro < 2.5m saat diam
  }) {
    if (accuracyMeters <= 0 || accuracyMeters > maxAccuracyThreshold) {
      return false;
    }
    if (distanceMeters < minDisplacement) {
      return false;
    }

    // Batas kecepatan wajar sesuai jenis aktivitas (mencegah teleportasi GPS)
    final double maxSpeedKmh = isBerlari ? 36.0 : 18.0;
    if (timeSeconds > 0) {
      final speedKmh = (distanceMeters / timeSeconds) * 3.6;
      if (speedKmh > maxSpeedKmh) return false;
    }

    return true;
  }

  /// Menghitung estimasi langkah alternatif berdasarkan tinggi badan dan jarak
  static int estimasiLangkahDariJarak({
    required double jarakMeter,
    required double tinggiBadanCm,
    required bool isBerlari,
  }) {
    final strideFactor = isBerlari ? 0.53 : 0.414;
    final strideLengthMeters = (tinggiBadanCm * strideFactor) / 100.0;
    if (strideLengthMeters <= 0.2) return 0;
    return (jarakMeter / strideLengthMeters).round();
  }

  /// Menghitung nilai MET dinamis berdasarkan jenis aktivitas dan kecepatan (km/jam)
  static double getMetValue({
    required bool isBerlari,
    required double speedKmh,
  }) {
    if (!isBerlari) {
      if (speedKmh < 3.2) return 2.3;
      if (speedKmh <= 4.5) return 3.0; // Berjalan santai
      if (speedKmh <= 5.5) return 3.6; // Berjalan sedang
      if (speedKmh <= 6.5) return 4.3; // Berjalan cepat
      return 5.0; // Berjalan sangat cepat
    } else {
      if (speedKmh < 7.5) return 6.5; // Jogging ringan
      if (speedKmh <= 9.0) return 8.3; // Lari santai
      if (speedKmh <= 10.5) return 9.8; // Lari sedang
      if (speedKmh <= 12.0) return 11.0; // Lari cepat
      return 12.5; // Lari intensitas tinggi
    }
  }

  /// Menghitung estimasi kalori terbakar menggunakan rumus MET standar:
  /// Kalori = (MET × 3.5 × Berat Badan [kg] / 200) × Durasi [menit]
  static double hitungKaloriMet({
    required double met,
    required double beratBadanKg,
    required double durasiMenit,
  }) {
    if (durasiMenit <= 0 || beratBadanKg <= 0) return 0.0;
    return (met * 3.5 * beratBadanKg / 200.0) * durasiMenit;
  }

  /// Format durasi menjadi HH:MM:SS
  static String formatDurasiHms(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:' '${s.toString().padLeft(2, '0')}';
  }

  /// Format jarak adaptif: meter (m) jika < 1000 m, kilometer (km) jika >= 1000 m
  static ({String nilai, String satuan}) formatJarakAdaptif(double meters) {
    if (meters < 1000) {
      return (nilai: meters.round().toString(), satuan: 'm');
    }
    final km = meters / 1000.0;
    return (
      nilai: km.toStringAsFixed(2).replaceAll('.', ','),
      satuan: 'km',
    );
  }

  /// Format Pace (Menit'Detik" /km)
  static String formatPace(double paceMinPerKm) {
    if (paceMinPerKm.isInfinite ||
        paceMinPerKm.isNaN ||
        paceMinPerKm <= 0 ||
        paceMinPerKm > 60) {
      return "--'--\" /km";
    }
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    if (seconds == 60) {
      return "${minutes + 1}’00” /km";
    }
    return "$minutes’${seconds.toString().padLeft(2, '0')}” /km";
  }

  /// Format Pace pendek untuk split
  static String formatPaceShort(double paceMinPerKm) {
    if (paceMinPerKm.isInfinite ||
        paceMinPerKm.isNaN ||
        paceMinPerKm <= 0 ||
        paceMinPerKm > 60) {
      return "--'--\"";
    }
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    if (seconds == 60) {
      return "${minutes + 1}’00”";
    }
    return "$minutes’${seconds.toString().padLeft(2, '0')}”";
  }
}