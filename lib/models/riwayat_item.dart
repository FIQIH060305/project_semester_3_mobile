class RiwayatItem {
  final String id;
  final String jenis; // 'Berjalan' atau 'Berlari'
  final DateTime tanggal;
  final double jarakKm;
  final int kalori;
  final int waktuMenit;
  final int langkah;
  final List<double> kecepatanSeries;

  RiwayatItem({
    required this.id,
    required this.jenis,
    required this.tanggal,
    required this.jarakKm,
    required this.kalori,
    required this.waktuMenit,
    required this.langkah,
    required this.kecepatanSeries,
  });

  String get waktuFormat {
    final jam = waktuMenit ~/ 60;
    final menit = waktuMenit % 60;
    if (jam > 0) return '${jam}j ${menit.toString().padLeft(2, '0')}m';
    return '${menit}m';
  }
}

List<RiwayatItem> dataDummyRiwayat() {
  final now = DateTime.now();
  return [
    RiwayatItem(id: '1', jenis: 'Berjalan', tanggal: now.subtract(const Duration(days: 0)), jarakKm: 3.3, kalori: 421, waktuMenit: 42, langkah: 4200, kecepatanSeries: [2, 3, 4, 5, 4, 6, 5]),
    RiwayatItem(id: '2', jenis: 'Berlari', tanggal: now.subtract(const Duration(days: 1)), jarakKm: 4.8, kalori: 638, waktuMenit: 62, langkah: 5980, kecepatanSeries: [5, 8, 12, 18, 22, 25, 24]),
    RiwayatItem(id: '3', jenis: 'Berjalan', tanggal: now.subtract(const Duration(days: 2)), jarakKm: 2.7, kalori: 287, waktuMenit: 28, langkah: 3600, kecepatanSeries: [2, 3, 3, 4, 4, 3, 4]),
    RiwayatItem(id: '4', jenis: 'Berlari', tanggal: now.subtract(const Duration(days: 3)), jarakKm: 5.6, kalori: 722, waktuMenit: 70, langkah: 7100, kecepatanSeries: [6, 10, 14, 20, 24, 26, 23]),
    RiwayatItem(id: '5', jenis: 'Berjalan', tanggal: now.subtract(const Duration(days: 4)), jarakKm: 2.7, kalori: 503, waktuMenit: 41, langkah: 3500, kecepatanSeries: [2, 3, 4, 4, 5, 4, 5]),
    RiwayatItem(id: '6', jenis: 'Berjalan', tanggal: now.subtract(const Duration(days: 5)), jarakKm: 2.7, kalori: 503, waktuMenit: 33, langkah: 3400, kecepatanSeries: [2, 3, 3, 4, 5, 4, 4]),
    RiwayatItem(id: '7', jenis: 'Berjalan', tanggal: now.subtract(const Duration(days: 6)), jarakKm: 2.3, kalori: 503, waktuMenit: 33, langkah: 3200, kecepatanSeries: [2, 2, 3, 4, 4, 3, 3]),
  ];
}