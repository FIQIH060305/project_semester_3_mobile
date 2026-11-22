import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class RiwayatItem {
  final String id;
  final String jenis; // 'Berjalan' atau 'Berlari'
  final DateTime tanggal;
  final double jarakKm;
  final int kalori;
  final int waktuMenit;
  final int durasiDetik;
  final int langkah;
  final bool sensorLangkahTersedia;
  final String paceRataRata;
  final double kecepatanRataRataKmh;
  final List<double> kecepatanSeries;
  final List<LatLng> rutePoints;

  RiwayatItem({
    required this.id,
    required this.jenis,
    required this.tanggal,
    required this.jarakKm,
    required this.kalori,
    required this.waktuMenit,
    int? durasiDetik,
    required this.langkah,
    this.sensorLangkahTersedia = true,
    this.paceRataRata = "--'--\" /km",
    double? kecepatanRataRataKmh,
    required this.kecepatanSeries,
    this.rutePoints = const [],
  })  : durasiDetik = durasiDetik ?? (waktuMenit * 60),
        kecepatanRataRataKmh = kecepatanRataRataKmh ??
            (waktuMenit > 0 ? (jarakKm / (waktuMenit / 60.0)) : 0.0);

  String get waktuFormat {
    final totalMenit = durasiDetik >= 60 ? (durasiDetik ~/ 60) : waktuMenit;
    final jam = totalMenit ~/ 60;
    final menit = totalMenit % 60;
    if (jam > 0) return '${jam}j${menit.toString().padLeft(2, '0')}m';
    if (durasiDetik > 0 && durasiDetik < 60) return '${durasiDetik}d';
    return '${menit}m';
  }

  String get durasiHms {
    final h = durasiDetik ~/ 3600;
    final m = (durasiDetik % 3600) ~/ 60;
    final s = durasiDetik % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:' '${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jenis': jenis,
        'tanggal': tanggal.toIso8601String(),
        'jarakKm': jarakKm,
        'kalori': kalori,
        'waktuMenit': waktuMenit,
        'durasiDetik': durasiDetik,
        'langkah': langkah,
        'sensorLangkahTersedia': sensorLangkahTersedia,
        'paceRataRata': paceRataRata,
        'kecepatanRataRataKmh': kecepatanRataRataKmh,
        'kecepatanSeries': kecepatanSeries,
        'rutePoints': rutePoints
            .map((p) => {'lat': p.latitude, 'lon': p.longitude})
            .toList(),
      };

  factory RiwayatItem.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['rutePoints'] as List<dynamic>? ?? const [];
    final points = rawPoints
        .whereType()
        .map((m) => LatLng(
              (m['lat'] as num).toDouble(),
              (m['lon'] as num).toDouble(),
            ))
        .toList();

    final rawSeries = json['kecepatanSeries'] as List<dynamic>? ?? const [];
    final series = rawSeries.map((e) => (e as num).toDouble()).toList();

    return RiwayatItem(
      id: (json['id'] ?? '').toString(),
      jenis: (json['jenis'] ?? 'Berlari').toString(),
      tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? '') ??
          DateTime.now(),
      jarakKm: (json['jarakKm'] as num?)?.toDouble() ?? 0.0,
      kalori: (json['kalori'] as num?)?.toInt() ?? 0,
      waktuMenit: (json['waktuMenit'] as num?)?.toInt() ?? 1,
      durasiDetik: (json['durasiDetik'] as num?)?.toInt(),
      langkah: (json['langkah'] as num?)?.toInt() ?? 0,
      sensorLangkahTersedia: json['sensorLangkahTersedia'] as bool? ?? true,
      paceRataRata: (json['paceRataRata'] ?? "--'--\" /km").toString(),
      kecepatanRataRataKmh:
          (json['kecepatanRataRataKmh'] as num?)?.toDouble(),
      kecepatanSeries:
          series.isNotEmpty ? series : const [3.5, 4.5, 5.2, 4.8, 4.2],
      rutePoints: points,
    );
  }
}

/// Service terpusat untuk menyimpan & mengagregasi riwayat aktivitas pengguna
/// (Terhubung ke Riwayat Olahraga, Progres, dan Dashboard)
class RiwayatService extends ChangeNotifier {
  RiwayatService._();
  static final RiwayatService instance = RiwayatService._();

  final List<RiwayatItem> _items = [];
  bool _initialized = false;
  bool isLoading = false;

  List<RiwayatItem> get semuaRiwayat => List.unmodifiable(_items);

  String get _storageKey {
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      return 'gerak_riwayat_aktivitas_$userId';
    }
    return 'gerak_riwayat_aktivitas_guest';
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;
    _initialized = true;

    await _loadFromLocal();
    await syncFromServer();
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(decoded
              .whereType()
              .map((m) => RiwayatItem.fromJson(Map<String, dynamic>.from(m))));
        _items.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> syncFromServer() async {
    if (!AuthService.instance.isLoggedIn) return;
    isLoading = true;
    notifyListeners();

    try {
      final rawList = await AuthService.instance.fetchRiwayatOlahraga();
      if (rawList.isEmpty && _items.isNotEmpty) {
        return;
      }

      // Pertahankan rute GPS lokal jika item sudah tersimpan di perangkat
      final localById = {for (final item in _items) item.id: item};
      final merged = <RiwayatItem>[];

      for (final row in rawList) {
        final id = (row['id_aktivitas'] ?? row['id'] ?? '').toString();
        final existingLocal = localById[id];

        final jenisRaw = (row['jenis_olahraga'] ?? 'Berlari').toString();
        final jenisNormalized = jenisRaw.toLowerCase().contains('jalan')
            ? 'Berjalan'
            : 'Berlari';

        final jarak =
            double.tryParse(row['jarak_km']?.toString() ?? '0') ?? 0.0;
        final durasiDetik =
            int.tryParse(row['durasi_detik']?.toString() ?? '0') ?? 0;
        final langkah =
            int.tryParse(row['jumlah_langkah']?.toString() ?? '0') ?? 0;
        final kalori =
            (double.tryParse(row['kalori_terbakar']?.toString() ?? '0') ?? 0.0)
                .round();

        DateTime tanggal = DateTime.now();
        final createdStr =
            (row['created_at'] ?? row['tanggal'] ?? '').toString();
        if (createdStr.isNotEmpty) {
          tanggal = DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now();
        }

        final menit = (durasiDetik / 60).round().clamp(1, 9999);
        final avgSpeedKmh = durasiDetik > 0
            ? (jarak / (durasiDetik / 3600.0)).clamp(0.0, 40.0)
            : 0.0;

        String paceStr = "--'--\" /km";
        if (jarak > 0.01 && durasiDetik > 0) {
          final paceMin = (durasiDetik / 60.0) / jarak;
          final pm = paceMin.floor();
          final ps = ((paceMin - pm) * 60).round();
          paceStr = "$pm’${ps.toString().padLeft(2, '0')}” /km";
        }

        final series = existingLocal?.kecepatanSeries ??
            <double>[
              double.parse((avgSpeedKmh * 0.80).toStringAsFixed(1)),
              double.parse((avgSpeedKmh * 0.95).toStringAsFixed(1)),
              double.parse((avgSpeedKmh * 1.08).toStringAsFixed(1)),
              double.parse((avgSpeedKmh * 1.12).toStringAsFixed(1)),
              double.parse((avgSpeedKmh * 1.00).toStringAsFixed(1)),
              double.parse((avgSpeedKmh * 0.90).toStringAsFixed(1)),
            ];

        merged.add(
          RiwayatItem(
            id: id,
            jenis: jenisNormalized,
            tanggal: tanggal,
            jarakKm: double.parse(jarak.toStringAsFixed(2)),
            kalori: kalori,
            waktuMenit: menit,
            durasiDetik: durasiDetik > 0 ? durasiDetik : (menit * 60),
            langkah: langkah,
            sensorLangkahTersedia:
                existingLocal?.sensorLangkahTersedia ?? (langkah > 0),
            paceRataRata: existingLocal?.paceRataRata ?? paceStr,
            kecepatanRataRataKmh:
                existingLocal?.kecepatanRataRataKmh ?? avgSpeedKmh,
            kecepatanSeries: series,
            rutePoints: existingLocal?.rutePoints ?? const [],
          ),
        );
      }

      // Sertakan aktivitas lokal yang belum terunggah (offline)
      final serverIds = merged.map((e) => e.id).toSet();
      for (final localItem in _items) {
        if (!serverIds.contains(localItem.id)) {
          merged.add(localItem);
        }
      }

      merged.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      _items
        ..clear()
        ..addAll(merged);
      await _saveToLocal();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tambahAktivitas(RiwayatItem item) async {
    _items.insert(0, item);
    await _saveToLocal();
    notifyListeners();
  }

  // ── Agregasi Statistik untuk Fitur Progres & Dashboard ───────────────
  int get totalAktivitas => _items.length;

  int get totalBerjalan =>
      _items.where((e) => e.jenis == 'Berjalan').length;

  int get totalBerlari =>
      _items.where((e) => e.jenis == 'Berlari').length;

  double get totalJarakKm =>
      _items.fold<double>(0.0, (sum, e) => sum + e.jarakKm);

  int get totalDurasiMenit =>
      _items.fold<int>(0, (sum, e) => sum + e.waktuMenit);

  int get totalLangkah =>
      _items.fold<int>(0, (sum, e) => sum + e.langkah);

  int get totalKalori =>
      _items.fold<int>(0, (sum, e) => sum + e.kalori);

  List<RiwayatItem> get aktivitasHariIni {
    final now = DateTime.now();
    return _items.where((e) {
      return e.tanggal.year == now.year &&
          e.tanggal.month == now.month &&
          e.tanggal.day == now.day;
    }).toList();
  }

  List<RiwayatItem> get aktivitasMingguIni {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return _items.where((e) => !e.tanggal.isBefore(startOfWeek)).toList();
  }

  double get jarakMingguIniKm =>
      aktivitasMingguIni.fold<double>(0.0, (sum, e) => sum + e.jarakKm);

  int get kaloriMingguIni =>
      aktivitasMingguIni.fold<int>(0, (sum, e) => sum + e.kalori);

  int get langkahMingguIni =>
      aktivitasMingguIni.fold<int>(0, (sum, e) => sum + e.langkah);

  int get durasiMingguIniMenit =>
      aktivitasMingguIni.fold<int>(0, (sum, e) => sum + e.waktuMenit);

  void reset() {
    _items.clear();
    _initialized = false;
    notifyListeners();
  }
}

/// Helper kompatibilitas untuk layar lain yang membaca riwayat aktivitas aktual
List<RiwayatItem> dataDummyRiwayat() {
  return RiwayatService.instance.semuaRiwayat;
}

void simpanRiwayatBaru(RiwayatItem item) {
  RiwayatService.instance.tambahAktivitas(item);
}