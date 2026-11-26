import 'package:flutter/foundation.dart';
import '../models/jadwal_item.dart';
import 'auth_service.dart';

class JadwalService extends ChangeNotifier {
  JadwalService._();
  static final JadwalService instance = JadwalService._();

  final List<JadwalItem> _jadwalList = [];
  bool _initialized = false;
  bool isLoading = false;

  List<JadwalItem> get semuaJadwal => List.unmodifiable(_jadwalList);

  Future<void> initialize(
      {List<JadwalItem>? savedData, bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;
    _initialized = true;

    if (AuthService.instance.isLoggedIn) {
      await syncFromServer();
      return;
    }

    if (savedData != null && savedData.isNotEmpty) {
      _jadwalList
        ..clear()
        ..addAll(savedData);
    } else if (_jadwalList.isEmpty) {
      _jadwalList.addAll(dataDummyJadwal());
    }
    _prosesRecurringTertunda();
    notifyListeners();
  }

  Future<void> syncFromServer() async {
    if (!AuthService.instance.isLoggedIn) return;
    isLoading = true;
    notifyListeners();

    try {
      final existingById = {
        for (final item in _jadwalList) item.id: item,
      };

      final results = await Future.wait([
        AuthService.instance.fetchJadwalList(),
        AuthService.instance.fetchUserRekomendasiOlahraga(),
      ]);

      final rows = results[0];
      final rekomRows = results[1];

      _jadwalList.clear();
      final linkedRekomIds = <String>{};

      for (final row in rows) {
        final idStr = (row['id_jadwal'] ?? '').toString();
        final prev = existingById[idStr];
        final tglRaw = row['tanggal_tugas']?.toString() ?? '';
        final parsedDate = DateTime.tryParse(tglRaw) ?? DateTime.now();

        int jam = prev?.tanggal.hour ?? 7;
        int menit = prev?.tanggal.minute ?? 0;
        final waktuRaw = row['waktu_latihan']?.toString() ?? '';
        if (waktuRaw.contains(':')) {
          final parts = waktuRaw.split(':');
          jam = int.tryParse(parts[0]) ?? jam;
          menit = int.tryParse(parts[1]) ?? menit;
        }

        final tglDenganJam = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          jam,
          menit,
        );

        final isFromCoach =
            row['dari_coach'] == true || row['coach_id'] != null;
        final rekomId = row['rekomendasi_id']?.toString();
        if (rekomId != null && rekomId.isNotEmpty) {
          linkedRekomIds.add(rekomId);
        }

        _jadwalList.add(
          JadwalItem(
            id: idStr,
            judul: (row['tugas'] ?? 'Latihan GERAK').toString(),
            tanggal: tglDenganJam,
            selesai: row['selesai'] == true,
            ulangi: prev?.ulangi ?? false,
            frekuensi: prev?.frekuensi ?? FrekuensiUlang.tidakUlang,
            parentId: prev?.parentId,
            dariPelatih: isFromCoach,
            rekomendasiId: rekomId,
            namaPelatih: row['nama_coach']?.toString(),
            durasiMenit: row['durasi_menit'] != null
                ? int.tryParse(row['durasi_menit'].toString())
                : null,
            intensitas: row['intensitas']?.toString(),
            targetLatihan: row['target']?.toString(),
            catatanPelatih: row['catatan_coach']?.toString(),
            statusPersetujuan:
                (row['status_persetujuan'] ?? 'accepted').toString(),
            alasanPenolakan: row['alasan_penolakan']?.toString(),
          ),
        );
      }

      // Tambahkan rekomendasi jadwal olahraga dari Pelatih yang belum masuk daftar jadwal (misal status pending)
      for (final r in rekomRows) {
        final rId = (r['id'] ?? '').toString();
        if (rId.isEmpty || linkedRekomIds.contains(rId)) continue;

        final statusUser =
            (r['status_user'] ?? r['status'] ?? 'pending').toString();
        if (statusUser == 'rejected') continue;

        final tglRaw =
            (r['tanggal'] ?? r['tanggal_latihan'] ?? '').toString();
        final parsedDate = DateTime.tryParse(tglRaw) ?? DateTime.now();

        int jam = 7;
        int menit = 0;
        final waktuRaw =
            (r['waktu'] ?? r['waktu_latihan'] ?? '07:00').toString();
        if (waktuRaw.contains(':')) {
          final parts = waktuRaw.split(':');
          jam = int.tryParse(parts[0]) ?? jam;
          menit = int.tryParse(parts[1]) ?? menit;
        }

        _jadwalList.add(
          JadwalItem(
            id: 'rekom_$rId',
            judul: (r['nama_olahraga'] ?? r['judul_latihan'] ?? 'Latihan')
                .toString(),
            tanggal: DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              jam,
              menit,
            ),
            selesai: false,
            dariPelatih: true,
            rekomendasiId: rId,
            namaPelatih:
                (r['nama_coach'] ?? r['coach']?['nama'] ?? 'Pelatih GERAK')
                    .toString(),
            durasiMenit: r['durasi'] != null
                ? int.tryParse(r['durasi'].toString())
                : null,
            intensitas: r['intensitas']?.toString(),
            targetLatihan: r['target']?.toString(),
            catatanPelatih: r['catatan']?.toString(),
            statusPersetujuan: statusUser,
            alasanPenolakan: r['alasan_penolakan']?.toString(),
          ),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResult> respondRekomendasiPelatih({
    required JadwalItem item,
    required String aksi, // 'accepted' | 'rejected'
    String? catatan,
  }) async {
    final rekomId = item.rekomendasiId ?? item.id.replaceFirst('rekom_', '');
    final res = await AuthService.instance.respondRekomendasiOlahraga(
      rekomendasiId: rekomId,
      aksi: aksi,
      catatan: catatan,
    );
    if (res.isSuccess) {
      await syncFromServer();
    }
    return res;
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERIES PENGELOMPOKAN
  // ═══════════════════════════════════════════════════════════════

  List<JadwalItem> get menungguPersetujuan =>
      _jadwalList.where((j) => j.menungguKonfirmasi).toList()
        ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

  List<JadwalItem> get terlambat => _jadwalList
      .where((j) => !j.menungguKonfirmasi && j.kategoriWaktu == 'Terlambat')
      .toList()
    ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

  List<JadwalItem> get hariIni => _jadwalList
      .where((j) => !j.menungguKonfirmasi && j.kategoriWaktu == 'Hari ini')
      .toList()
    ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

  List<JadwalItem> get besok => _jadwalList
      .where((j) => !j.menungguKonfirmasi && j.kategoriWaktu == 'Besok')
      .toList()
    ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

  List<JadwalItem> get mingguDepan => _jadwalList
      .where((j) => !j.menungguKonfirmasi && j.kategoriWaktu == 'Minggu depan')
      .toList()
    ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

  List<JadwalItem> get riwayatSelesai => _jadwalList
      .where((j) => !j.menungguKonfirmasi && j.kategoriWaktu == 'Selesai')
      .toList()
    ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

  int get jumlahBelumSelesai => _jadwalList.where((j) => !j.selesai).length;

  int get jumlahTerlambat => terlambat.length;

  int get jumlahTersisaMingguIni {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sisaHariKeAkhirMinggu = DateTime.sunday - today.weekday;
    final akhirMinggu = today.add(Duration(
        days: sisaHariKeAkhirMinggu < 0
            ? 7 + sisaHariKeAkhirMinggu
            : sisaHariKeAkhirMinggu));

    return _jadwalList.where((j) {
      if (j.selesai || j.menungguKonfirmasi) return false;
      final tgl = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      return tgl.compareTo(today) >= 0 && tgl.compareTo(akhirMinggu) <= 0;
    }).length;
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD OPERATIONS (TERHUBUNG KE SERVER LARAVEL)
  // ═══════════════════════════════════════════════════════════════

  Future<void> tambahJadwal(JadwalItem item) async {
    _jadwalList.add(item);
    notifyListeners();

    if (AuthService.instance.isLoggedIn) {
      final created = await AuthService.instance.createJadwalOnServer(
        tugas: item.judul,
        tanggalTugas: item.tanggal,
      );
      if (created != null && created['id_jadwal'] != null) {
        final idx = _jadwalList.indexWhere((j) => j.id == item.id);
        if (idx != -1) {
          _jadwalList[idx] =
              item.copyWith(id: created['id_jadwal'].toString());
          notifyListeners();
        }
      }
    }
  }

  Future<void> hapusJadwal(String id) async {
    _jadwalList.removeWhere((j) => j.id == id);
    notifyListeners();

    if (AuthService.instance.isLoggedIn && !id.startsWith('rekom_')) {
      await AuthService.instance.deleteJadwalOnServer(id);
    }
  }

  void editJadwal(
    String id, {
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

  Future<void> gantiJadwal(String id, JadwalItem itemBaru) async {
    final idx = _jadwalList.indexWhere((j) => j.id == id);
    if (idx == -1) return;
    _jadwalList[idx] = itemBaru;
    notifyListeners();

    if (AuthService.instance.isLoggedIn && !id.startsWith('rekom_')) {
      await AuthService.instance.deleteJadwalOnServer(id);
      final created = await AuthService.instance.createJadwalOnServer(
        tugas: itemBaru.judul,
        tanggalTugas: itemBaru.tanggal,
      );
      if (created != null && created['id_jadwal'] != null) {
        final newIdx = _jadwalList.indexWhere((j) => j.id == itemBaru.id);
        if (newIdx != -1) {
          _jadwalList[newIdx] =
              itemBaru.copyWith(id: created['id_jadwal'].toString());
          notifyListeners();
        }
      }
    }
  }

  Future<void> toggleSelesai(JadwalItem item) async {
    if (item.menungguKonfirmasi) return;

    final idx = _jadwalList.indexWhere((j) => j.id == item.id);
    if (idx == -1) return;

    final jadwal = _jadwalList[idx];
    final baruSelesai = !jadwal.selesai;

    _jadwalList[idx] = jadwal.copyWith(selesai: baruSelesai);

    if (baruSelesai &&
        jadwal.ulangi &&
        jadwal.frekuensi != FrekuensiUlang.tidakUlang) {
      await _buatJadwalRecurring(jadwal);
    }

    notifyListeners();

    if (AuthService.instance.isLoggedIn && !jadwal.id.startsWith('rekom_')) {
      await AuthService.instance.toggleJadwalOnServer(jadwal.id);
    }
  }

  Future<void> _buatJadwalRecurring(JadwalItem jadwalSelesai) async {
    final tanggalBaru = jadwalSelesai.tanggalBerikutnya;
    final rootId = jadwalSelesai.parentId ?? jadwalSelesai.id;

    final sudahAda = _jadwalList.any((j) {
      if (j.selesai) return false;
      final jRoot = j.parentId ?? j.id;
      if (jRoot != rootId && j.parentId != jadwalSelesai.id) return false;
      final tglJ = DateTime(j.tanggal.year, j.tanggal.month, j.tanggal.day);
      final tglB =
          DateTime(tanggalBaru.year, tanggalBaru.month, tanggalBaru.day);
      return tglJ == tglB && j.judul == jadwalSelesai.judul;
    });

    if (!sudahAda) {
      final jadwalBaru = jadwalSelesai.buatJadwalBerikutnya();
      _jadwalList.add(jadwalBaru);

      if (AuthService.instance.isLoggedIn) {
        final created = await AuthService.instance.createJadwalOnServer(
          tugas: jadwalBaru.judul,
          tanggalTugas: jadwalBaru.tanggal,
        );
        if (created != null && created['id_jadwal'] != null) {
          final newIdx = _jadwalList.indexWhere((j) => j.id == jadwalBaru.id);
          if (newIdx != -1) {
            _jadwalList[newIdx] =
                jadwalBaru.copyWith(id: created['id_jadwal'].toString());
          }
        }
      }
    }
  }

  void _prosesRecurringTertunda() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final jadwalSelesaiRecurring = _jadwalList
        .where((j) =>
            j.selesai && j.ulangi && j.frekuensi != FrekuensiUlang.tidakUlang)
        .toList();

    for (final jadwal in jadwalSelesaiRecurring) {
      final rootId = jadwal.parentId ?? jadwal.id;

      final adaPenerus = _jadwalList.any((j) {
        if (j.selesai) return false;
        final jRoot = j.parentId ?? j.id;
        return (jRoot == rootId || j.parentId == jadwal.id) &&
            j.judul == jadwal.judul;
      });

      if (!adaPenerus) {
        var tanggalBaru = jadwal.tanggalBerikutnya;
        final tanggalHariIni = DateTime(today.year, today.month, today.day);

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

  String toJsonString() => JadwalItem.encodeList(_jadwalList);

  void reset() {
    _jadwalList.clear();
    _initialized = false;
  }
}