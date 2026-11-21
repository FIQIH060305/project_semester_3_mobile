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

  Future<void> initialize({List<JadwalItem>? savedData, bool forceRefresh = false}) async {
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
      final rows = await AuthService.instance.fetchJadwalList();
      _jadwalList.clear();

      for (final row in rows) {
        final tglRaw = row['tanggal_tugas']?.toString() ?? '';
        final parsedDate = DateTime.tryParse(tglRaw) ?? DateTime.now();
        final tglDenganJam = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          7,
          0,
        );

        _jadwalList.add(
          JadwalItem(
            id: (row['id_jadwal'] ?? '').toString(),
            judul: (row['tugas'] ?? 'Latihan GERAK').toString(),
            tanggal: tglDenganJam,
            selesai: row['selesai'] == true,
            ulangi: false,
            frekuensi: FrekuensiUlang.tidakUlang,
          ),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════

  List<JadwalItem> get terlambat =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Terlambat').toList();

  List<JadwalItem> get hariIni =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Hari ini').toList();

  List<JadwalItem> get besok =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Besok').toList();

  List<JadwalItem> get mingguDepan =>
      _jadwalList.where((j) => j.kategoriWaktu == 'Minggu depan').toList();

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
      if (j.selesai) return false;
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

    if (AuthService.instance.isLoggedIn) {
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

    if (AuthService.instance.isLoggedIn) {
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
    final idx = _jadwalList.indexWhere((j) => j.id == item.id);
    if (idx == -1) return;

    final jadwal = _jadwalList[idx];
    final baruSelesai = !jadwal.selesai;

    _jadwalList[idx] = jadwal.copyWith(selesai: baruSelesai);

    if (baruSelesai &&
        jadwal.ulangi &&
        jadwal.frekuensi != FrekuensiUlang.tidakUlang) {
      _buatJadwalRecurring(jadwal);
    }

    notifyListeners();

    if (AuthService.instance.isLoggedIn) {
      await AuthService.instance.toggleJadwalOnServer(jadwal.id);
    }
  }

  void _buatJadwalRecurring(JadwalItem jadwalSelesai) {
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