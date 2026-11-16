import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/jadwal_item.dart';

/// Service pusat untuk mengelola semua operasi jadwal latihan.
///
/// Menggunakan pola ChangeNotifier agar widget bisa listen perubahan.
/// Data disimpan in-memory dan di-persist via SharedPreferences oleh caller.
class JadwalService extends ChangeNotifier {
  JadwalService._();
  static final JadwalService instance = JadwalService._();

  /// Daftar semua jadwal
  final List<JadwalItem> _jadwalList = [];

  /// Apakah sudah diinisialisasi
  bool _initialized = false;

  /// Getter untuk daftar jadwal (unmodifiable view)
  List<JadwalItem> get semuaJadwal => List.unmodifiable(_jadwalList);

  /// Inisialisasi data dari SharedPreferences atau dummy
  void initialize({List<JadwalItem>? savedData}) {
    if (_initialized) return;
    _initialized = true;

    if (savedData != null && savedData.isNotEmpty) {
      _jadwalList.addAll(savedData);
    } else {
      _jadwalList.addAll(dataDummyJadwal());
    }

    // Periksa jadwal recurring yang tertunda saat aplikasi dibuka
    _prosesRecurringTertunda();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════

  /// Jadwal yang belum selesai dan sudah lewat waktunya
  List<JadwalItem> get terlambat =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Terlambat').toList();

  /// Jadwal untuk hari ini
  List<JadwalItem> get hariIni =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Hari ini').toList();

  /// Jadwal untuk besok
  List<JadwalItem> get besok =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Besok').toList();

  /// Jadwal untuk minggu depan dan seterusnya
  List<JadwalItem> get mingguDepan =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Minggu depan').toList();

  /// Total jadwal belum selesai (semua yang belum dicentang)
  int get jumlahBelumSelesai => _jadwalList.where((j) => !j.selesai).length;

  /// Total jadwal yang terlambat (belum selesai dan sudah lewat tanggal)
  int get jumlahTerlambat => terlambat.length;

  /// Total jadwal tersisa minggu ini (belum selesai, tanggal dalam minggu ini)
  int get jumlahTersisaMingguIni {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Akhir minggu ini = Minggu berikutnya
    final sisaHariKeAkhirMinggu = DateTime.sunday - today.weekday;
    final akhirMinggu = today.add(Duration(days: sisaHariKeAkhirMinggu < 0 ? 7 + sisaHariKeAkhirMinggu : sisaHariKeAkhirMinggu));

    return _jadwalList.where((j) {
      if (j.selesai) return false;
      final tgl = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      return tgl.compareTo(today) >= 0 && tgl.compareTo(akhirMinggu) <= 0;
    }).length;
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Tambah jadwal baru
  void tambahJadwal(JadwalItem item) {
    _jadwalList.add(item);
    notifyListeners();
  }

  /// Hapus jadwal berdasarkan ID
  void hapusJadwal(String id) {
    _jadwalList.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  /// Edit jadwal (ganti data lama dengan data baru, pertahankan ID)
  void editJadwal(String id, {
    String? judul,
    DateTime? tanggal,
    bool? ulangi,
    FrekuensiUlang? frekuensi,
  }) {
    final idx = _jadwalList.indexWhere((j) => j.id == id);
    if (idx == -1) return;

    final existing = _jadwalList[idx];
    _jadwalList[idx] = existing.copyWith(
      judul: judul ?? existing.judul,
      tanggal: tanggal ?? existing.tanggal,
      ulangi: ulangi ?? existing.ulangi,
      frekuensi: frekuensi ?? existing.frekuensi,
    );
    notifyListeners();
  }

  /// Ganti seluruh item jadwal pada index tertentu
  void gantiJadwal(String id, JadwalItem itemBaru) {
    final idx = _jadwalList.indexWhere((j) => j.id == id);
    if (idx == -1) return;
    _jadwalList[idx] = itemBaru;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // CHECKLIST & RECURRING
  // ═══════════════════════════════════════════════════════════════

  /// Toggle status selesai/belum selesai pada jadwal.
  ///
  /// Jika mencentang (selesai = true) dan jadwal memiliki pengulangan aktif,
  /// maka otomatis membuat jadwal berikutnya sesuai frekuensi.
  ///
  /// Jika membatalkan centang (selesai = false), tidak membuat jadwal duplikat.
  void toggleSelesai(JadwalItem item) {
    final idx = _jadwalList.indexWhere((j) => j.id == item.id);
    if (idx == -1) return;

    final jadwal = _jadwalList[idx];
    final baruSelesai = !jadwal.selesai;

    _jadwalList[idx] = jadwal.copyWith(selesai: baruSelesai);

    if (baruSelesai && jadwal.ulangi && jadwal.frekuensi != FrekuensiUlang.tidakUlang) {
      _buatJadwalRecurring(jadwal);
    }

    notifyListeners();
  }

  /// Buat jadwal berikutnya dari jadwal yang selesai (recurring).
  /// Memastikan tidak ada duplikasi.
  void _buatJadwalRecurring(JadwalItem jadwalSelesai) {
    final tanggalBaru = jadwalSelesai.tanggalBerikutnya;
    final rootId = jadwalSelesai.parentId ?? jadwalSelesai.id;

    // Cek apakah sudah ada jadwal berikutnya yang belum selesai untuk rantai ini
    final sudahAda = _jadwalList.any((j) {
      if (j.selesai) return false;
      final jRoot = j.parentId ?? j.id;
      if (jRoot != rootId && j.parentId != jadwalSelesai.id) return false;
      final tglJ = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      final tglB = DateTime(tanggalBaru.year, tanggalBaru.month, tanggalBaru.day);
      return tglJ == tglB && j.judul == jadwalSelesai.judul;
    });

    if (!sudahAda) {
      final jadwalBaru = jadwalSelesai.buatJadwalBerikutnya();
      _jadwalList.add(jadwalBaru);
    }
  }

  /// Proses jadwal recurring yang tertunda (misalnya saat aplikasi baru dibuka
  /// setelah beberapa hari tidak aktif).
  void _prosesRecurringTertunda() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Kumpulkan jadwal recurring yang sudah selesai tapi belum punya penerus
    final jadwalSelesaiRecurring = _jadwalList
        .where((j) => j.selesai && j.ulangi && j.frekuensi != FrekuensiUlang.tidakUlang)
        .toList();

    for (final jadwal in jadwalSelesaiRecurring) {
      final rootId = jadwal.parentId ?? jadwal.id;

      // Cek apakah sudah ada penerus yang belum selesai
      final adaPenerus = _jadwalList.any((j) {
        if (j.selesai) return false;
        final jRoot = j.parentId ?? j.id;
        return (jRoot == rootId || j.parentId == jadwal.id) && j.judul == jadwal.judul;
      });

      if (!adaPenerus) {
        // Buat penerus — mungkin perlu mengejar beberapa hari/minggu
        var tanggalBaru = jadwal.tanggalBerikutnya;
        final tanggalHariIni = DateTime(today.year, today.month, today.day);

        // Jika tanggalBaru sudah lewat, geser ke depan sampai >= hari ini
        while (DateTime(tanggalBaru.year, tanggalBaru.month, tanggalBaru.day)
            .isBefore(tanggalHariIni)) {
          if (jadwal.frekuensi == FrekuensiUlang.sekaliSehari) {
            tanggalBaru = tanggalBaru.add(const Duration(days: 1));
          } else {
            tanggalBaru = tanggalBaru.add(const Duration(days: 7));
          }
        }

        final jadwalBaru = JadwalItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${jadwal.id.hashCode}_catch',
          judul: jadwal.judul,
          tanggal: tanggalBaru,
          selesai: false,
          ulangi: jadwal.ulangi,
          frekuensi: jadwal.frekuensi,
          parentId: rootId,
        );

        _jadwalList.add(jadwalBaru);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PERSISTENCE HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Serialisasi seluruh data jadwal ke JSON string
  String toJsonString() => JadwalItem.encodeList(_jadwalList);

  /// Kembalikan ke keadaan awal (untuk testing)
  void reset() {
    _jadwalList.clear();
    _initialized = false;
  }
}
