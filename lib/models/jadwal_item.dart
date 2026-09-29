class JadwalItem {
  final String id;
  String judul;
  DateTime tanggal;
  bool selesai;
  bool ulangi;

  JadwalItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    this.selesai = false,
    this.ulangi = false,
  });

  // Dipakai untuk mengelompokkan jadwal jadi "Terlambat", "Besok", "Minggu depan"
  String get kategoriWaktu {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tgl = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final selisihHari = tgl.difference(today).inDays;

    if (selisihHari < 0 && !selesai) return 'Terlambat';
    if (selisihHari == 0) return 'Hari ini';
    if (selisihHari == 1) return 'Besok';
    return 'Minggu depan';
  }
}

// Data dummy sementara (frontend-only), nanti diganti hasil dari API
List<JadwalItem> dataDummyJadwal() {
  final now = DateTime.now();
  return [
    JadwalItem(id: '1', judul: 'Jalan 20 menit', tanggal: now.subtract(const Duration(days: 1))),
    JadwalItem(id: '2', judul: 'Jalan 20 menit', tanggal: now.subtract(const Duration(hours: 3))),
    JadwalItem(id: '3', judul: 'Berlari 30 menit', tanggal: now.add(const Duration(days: 1))),
    JadwalItem(id: '4', judul: 'Berlari 30 menit', tanggal: now.add(const Duration(days: 1, hours: 2))),
    JadwalItem(id: '5', judul: 'Push Up 25 repitisi', tanggal: now.add(const Duration(days: 4))),
    JadwalItem(id: '6', judul: 'Pull Up 30 Repitisi', tanggal: now.add(const Duration(days: 5))),
  ];
}