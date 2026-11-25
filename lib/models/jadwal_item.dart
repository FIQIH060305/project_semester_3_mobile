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

  // Penanda khusus apabila jadwal diberikan oleh Coach
  final bool dariCoach;
  final String? namaCoach;
  final int? durasiMenit;
  final String? intensitas;
  final String? catatanCoach;

  JadwalItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    this.selesai = false,
    this.ulangi = false,
    this.frekuensi = FrekuensiUlang.tidakUlang,
    this.parentId,
    this.dariCoach = false,
    this.namaCoach,
    this.durasiMenit,
    this.intensitas,
    this.catatanCoach,
  });

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
    if (selesai) return 'Tuntas';
    if (kategoriWaktu == 'Terlambat') return 'Terlewat';
    if (kategoriWaktu == 'Hari ini') return 'Hari ini';
    if (kategoriWaktu == 'Besok') return 'Besok';
    return 'Terjadwal';
  }

  String? get infoTargetLatihan {
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
      dariCoach: dariCoach,
      namaCoach: namaCoach,
      durasiMenit: durasiMenit,
      intensitas: intensitas,
      catatanCoach: catatanCoach,
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
    bool? dariCoach,
    String? namaCoach,
    int? durasiMenit,
    String? intensitas,
    String? catatanCoach,
  }) {
    return JadwalItem(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      tanggal: tanggal ?? this.tanggal,
      selesai: selesai ?? this.selesai,
      ulangi: ulangi ?? this.ulangi,
      frekuensi: frekuensi ?? this.frekuensi,
      parentId: parentId ?? this.parentId,
      dariCoach: dariCoach ?? this.dariCoach,
      namaCoach: namaCoach ?? this.namaCoach,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      intensitas: intensitas ?? this.intensitas,
      catatanCoach: catatanCoach ?? this.catatanCoach,
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
      'dariCoach': dariCoach,
      'namaCoach': namaCoach,
      'durasiMenit': durasiMenit,
      'intensitas': intensitas,
      'catatanCoach': catatanCoach,
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
      dariCoach: json['dariCoach'] as bool? ?? false,
      namaCoach: json['namaCoach'] as String?,
      durasiMenit: json['durasiMenit'] as int?,
      intensitas: json['intensitas'] as String?,
      catatanCoach: json['catatanCoach'] as String?,
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