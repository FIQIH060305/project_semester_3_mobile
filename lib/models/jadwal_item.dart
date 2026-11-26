import 'dart:convert';

enum FrekuensiUlang {
  tidakUlang,
  sekaliSehari,
  sekaliSeminggu,
}

class JadwalItem {
  final String id;
  String judul;
  DateTime tanggal;
  bool selesai;
  bool ulangi;
  FrekuensiUlang frekuensi;
  String? parentId;

  // Penanda khusus apabila jadwal diberikan oleh Pelatih
  final bool dariPelatih;
  final String? rekomendasiId;
  final String? namaPelatih;
  final int? durasiMenit;
  final String? intensitas;
  final String? targetLatihan;
  final String? catatanPelatih;
  final String statusPersetujuan; // 'pending' | 'accepted' | 'rejected'
  final String? alasanPenolakan;

  JadwalItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    this.selesai = false,
    this.ulangi = false,
    this.frekuensi = FrekuensiUlang.tidakUlang,
    this.parentId,
    this.dariPelatih = false,
    this.rekomendasiId,
    this.namaPelatih,
    this.durasiMenit,
    this.intensitas,
    this.targetLatihan,
    this.catatanPelatih,
    this.statusPersetujuan = 'accepted',
    this.alasanPenolakan,
  });

  bool get menungguKonfirmasi =>
      dariPelatih && statusPersetujuan == 'pending';

  bool get ditolakPeserta =>
      dariPelatih && statusPersetujuan == 'rejected';

  String get kategoriWaktu {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tgl = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final selisihHari = tgl.difference(today).inDays;

    if (selisihHari < 0 && !selesai) return 'Terlambat';
    if (selisihHari < 0 && selesai) return 'Selesai';
    if (selisihHari == 0) return 'Hari ini';
    if (selisihHari == 1) return 'Besok';
    return 'Minggu depan';
  }

  String get labelBadge {
    if (menungguKonfirmasi) return 'Perlu Konfirmasi';
    if (ditolakPeserta) return 'Ditolak';
    if (selesai) return 'Tuntas';
    if (kategoriWaktu == 'Terlambat') return 'Terlewat';
    if (kategoriWaktu == 'Hari ini') return 'Hari ini';
    if (kategoriWaktu == 'Besok') return 'Besok';
    return 'Terjadwal';
  }

  String? get infoTargetLatihan {
    if (targetLatihan != null && targetLatihan!.trim().isNotEmpty) {
      return targetLatihan!.trim();
    }
    if (durasiMenit != null && durasiMenit! > 0) {
      return '$durasiMenit menit';
    }
    final regex = RegExp(
      r'(\d+(?:[.,]\d+)?\s*(?:menit|mnt|jam|detik|repetisi|rep|set|kali|km|meter|m))',
      caseSensitive: false,
    );
    final match = regex.firstMatch(judul);
    return match?.group(1);
  }

  String get jamFormatted {
    final h = tanggal.hour.toString().padLeft(2, '0');
    final m = tanggal.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  DateTime get tanggalBerikutnya {
    switch (frekuensi) {
      case FrekuensiUlang.sekaliSehari:
        return tanggal.add(const Duration(days: 1));
      case FrekuensiUlang.sekaliSeminggu:
        return tanggal.add(const Duration(days: 7));
      case FrekuensiUlang.tidakUlang:
        return tanggal;
    }
  }

  JadwalItem buatJadwalBerikutnya() {
    return JadwalItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${id.hashCode}',
      judul: judul,
      tanggal: tanggalBerikutnya,
      selesai: false,
      ulangi: ulangi,
      frekuensi: frekuensi,
      parentId: parentId ?? id,
      dariPelatih: dariPelatih,
      rekomendasiId: rekomendasiId,
      namaPelatih: namaPelatih,
      durasiMenit: durasiMenit,
      intensitas: intensitas,
      targetLatihan: targetLatihan,
      catatanPelatih: catatanPelatih,
      statusPersetujuan: statusPersetujuan,
      alasanPenolakan: alasanPenolakan,
    );
  }

  JadwalItem copyWith({
    String? id,
    String? judul,
    DateTime? tanggal,
    bool? selesai,
    bool? ulangi,
    FrekuensiUlang? frekuensi,
    String? parentId,
    bool? dariPelatih,
    String? rekomendasiId,
    String? namaPelatih,
    int? durasiMenit,
    String? intensitas,
    String? targetLatihan,
    String? catatanPelatih,
    String? statusPersetujuan,
    String? alasanPenolakan,
  }) {
    return JadwalItem(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      tanggal: tanggal ?? this.tanggal,
      selesai: selesai ?? this.selesai,
      ulangi: ulangi ?? this.ulangi,
      frekuensi: frekuensi ?? this.frekuensi,
      parentId: parentId ?? this.parentId,
      dariPelatih: dariPelatih ?? this.dariPelatih,
      rekomendasiId: rekomendasiId ?? this.rekomendasiId,
      namaPelatih: namaPelatih ?? this.namaPelatih,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      intensitas: intensitas ?? this.intensitas,
      targetLatihan: targetLatihan ?? this.targetLatihan,
      catatanPelatih: catatanPelatih ?? this.catatanPelatih,
      statusPersetujuan: statusPersetujuan ?? this.statusPersetujuan,
      alasanPenolakan: alasanPenolakan ?? this.alasanPenolakan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'tanggal': tanggal.toIso8601String(),
      'selesai': selesai,
      'ulangi': ulangi,
      'frekuensi': frekuensi.index,
      'parentId': parentId,
      'dariPelatih': dariPelatih,
      'rekomendasiId': rekomendasiId,
      'namaPelatih': namaPelatih,
      'durasiMenit': durasiMenit,
      'intensitas': intensitas,
      'targetLatihan': targetLatihan,
      'catatanPelatih': catatanPelatih,
      'statusPersetujuan': statusPersetujuan,
      'alasanPenolakan': alasanPenolakan,
    };
  }

  factory JadwalItem.fromJson(Map<String, dynamic> json) {
    return JadwalItem(
      id: json['id'] as String,
      judul: json['judul'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      selesai: json['selesai'] as bool? ?? false,
      ulangi: json['ulangi'] as bool? ?? false,
      frekuensi: FrekuensiUlang.values[json['frekuensi'] as int? ?? 0],
      parentId: json['parentId'] as String?,
      dariPelatih:
          (json['dariPelatih'] ?? json['dariCoach']) as bool? ?? false,
      rekomendasiId: json['rekomendasiId'] as String?,
      namaPelatih: (json['namaPelatih'] ?? json['namaCoach']) as String?,
      durasiMenit: json['durasiMenit'] as int?,
      intensitas: json['intensitas'] as String?,
      targetLatihan: json['targetLatihan'] as String?,
      catatanPelatih:
          (json['catatanPelatih'] ?? json['catatanCoach']) as String?,
      statusPersetujuan:
          (json['statusPersetujuan'] ?? 'accepted').toString(),
      alasanPenolakan: json['alasanPenolakan'] as String?,
    );
  }

  static String encodeList(List<JadwalItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static List<JadwalItem> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list
        .map((e) => JadwalItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

List<JadwalItem> dataDummyJadwal() {
  final now = DateTime.now();
  return [
    JadwalItem(
      id: '1',
      judul: 'Jalan 20 menit',
      tanggal: DateTime(now.year, now.month, now.day, 7, 0)
          .subtract(const Duration(days: 1)),
      ulangi: true,
      frekuensi: FrekuensiUlang.sekaliSehari,
    ),
    JadwalItem(
      id: '3',
      judul: 'Berlari 30 menit',
      tanggal: DateTime(now.year, now.month, now.day + 1, 8, 0),
      ulangi: true,
      frekuensi: FrekuensiUlang.sekaliSeminggu,
    ),
  ];
}