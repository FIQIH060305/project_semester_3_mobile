import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/models/jadwal_item.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/jadwal_service.dart';

void main() {
  late JadwalService service;

  setUp(() {
    service = JadwalService.instance;
    service.reset();
  });

  group('Pengujian Fitur Jadwal Latihan & Logika Pengulangan', () {
    // 1. Tambah Jadwal Baru (Create)
    test('1. Tambah jadwal baru berhasil masuk ke dalam daftar', () {
      final now = DateTime.now();
      final itemBaru = JadwalItem(
        id: 'test_1',
        judul: 'Jogging Pagi 15 menit',
        tanggal: DateTime(now.year, now.month, now.day, 6, 30),
        ulangi: false,
      );

      service.tambahJadwal(itemBaru);

      expect(service.semuaJadwal.length, equals(1));
      expect(service.semuaJadwal.first.judul, equals('Jogging Pagi 15 menit'));
      expect(service.semuaJadwal.first.selesai, isFalse);
    });

    // 2. Edit Jadwal (Update)
    test('2. Edit data jadwal memperbarui nilai yang ada', () {
      final now = DateTime.now();
      final item = JadwalItem(
        id: 'test_edit',
        judul: 'Jalan santai',
        tanggal: DateTime(now.year, now.month, now.day, 7, 0),
        ulangi: false,
      );
      service.tambahJadwal(item);

      // Lakukan edit
      service.editJadwal(
        'test_edit',
        judul: 'Jalan Cepat 30 Menit',
        ulangi: true,
        frekuensi: FrekuensiUlang.sekaliSehari,
      );

      final edited = service.semuaJadwal.firstWhere((j) => j.id == 'test_edit');
      expect(edited.judul, equals('Jalan Cepat 30 Menit'));
      expect(edited.ulangi, isTrue);
      expect(edited.frekuensi, equals(FrekuensiUlang.sekaliSehari));
    });

    // 3. Hapus Jadwal (Delete)
    test('3. Hapus jadwal menghapus item yang dipilih tanpa merusak data lain', () {
      final now = DateTime.now();
      final item1 = JadwalItem(id: 'j1', judul: 'Latihan 1', tanggal: now);
      final item2 = JadwalItem(id: 'j2', judul: 'Latihan 2', tanggal: now);
      service.tambahJadwal(item1);
      service.tambahJadwal(item2);

      expect(service.semuaJadwal.length, equals(2));

      service.hapusJadwal('j1');

      expect(service.semuaJadwal.length, equals(1));
      expect(service.semuaJadwal.first.id, equals('j2'));
    });

    // 4. Checklist Latihan Non-recurring (sekali saja)
    test('4. Checklist latihan non-recurring menandai tuntas tanpa menjadwalkan ulang', () {
      final now = DateTime.now();
      final item = JadwalItem(
        id: 'j_sekali',
        judul: 'Berenang 45 menit',
        tanggal: DateTime(now.year, now.month, now.day, 9, 0),
        ulangi: false,
      );
      service.tambahJadwal(item);

      service.toggleSelesai(item);

      expect(service.semuaJadwal.length, equals(1));
      expect(service.semuaJadwal.first.selesai, isTrue);
    });

    // 5. Checklist Latihan Recurring: Sekali Sehari
    test('5. Checklist latihan Sekali Sehari otomatis membuat jadwal besok hari jam sama', () {
      final tglHariIni = DateTime(2026, 11, 16, 7, 0);
      final item = JadwalItem(
        id: 'j_harian',
        judul: 'Jalan 20 menit',
        tanggal: tglHariIni,
        ulangi: true,
        frekuensi: FrekuensiUlang.sekaliSehari,
      );
      service.tambahJadwal(item);

      // Centang latihan hari ini selesai
      service.toggleSelesai(item);

      // Jadwal lama ditandai selesai
      final lama = service.semuaJadwal.firstWhere((j) => j.id == 'j_harian');
      expect(lama.selesai, isTrue);

      // Jadwal baru otomatis tercipta untuk besok (17 Nov 2026, 07:00)
      expect(service.semuaJadwal.length, equals(2));
      final baru = service.semuaJadwal.firstWhere((j) => j.id != 'j_harian');
      expect(baru.judul, equals('Jalan 20 menit'));
      expect(baru.selesai, isFalse); // Belum dicentang
      expect(baru.tanggal.year, equals(2026));
      expect(baru.tanggal.month, equals(11));
      expect(baru.tanggal.day, equals(17));
      expect(baru.tanggal.hour, equals(7));
      expect(baru.tanggal.minute, equals(0));
      expect(baru.frekuensi, equals(FrekuensiUlang.sekaliSehari));
      expect(baru.ulangi, isTrue);
    });

    // 6. Checklist Latihan Recurring: Sekali Seminggu
    test('6. Checklist latihan Sekali Seminggu otomatis membuat jadwal 7 hari ke depan', () {
      final tglSenin = DateTime(2026, 11, 16, 7, 0); // Hari Senin
      final item = JadwalItem(
        id: 'j_mingguan',
        judul: 'Jalan 20 menit',
        tanggal: tglSenin,
        ulangi: true,
        frekuensi: FrekuensiUlang.sekaliSeminggu,
      );
      service.tambahJadwal(item);

      // Centang latihan selesai
      service.toggleSelesai(item);

      // Jadwal lama selesai
      final lama = service.semuaJadwal.firstWhere((j) => j.id == 'j_mingguan');
      expect(lama.selesai, isTrue);

      // Jadwal baru otomatis tercipta 7 hari kemudian (23 Nov 2026, 07:00)
      expect(service.semuaJadwal.length, equals(2));
      final baru = service.semuaJadwal.firstWhere((j) => j.id != 'j_mingguan');
      expect(baru.judul, equals('Jalan 20 menit'));
      expect(baru.selesai, isFalse);
      expect(baru.tanggal.year, equals(2026));
      expect(baru.tanggal.month, equals(11));
      expect(baru.tanggal.day, equals(23)); // 16 + 7 hari = 23
      expect(baru.tanggal.hour, equals(7));
      expect(baru.tanggal.minute, equals(0));
      expect(baru.frekuensi, equals(FrekuensiUlang.sekaliSeminggu));
    });

    // 7. Pencegahan Duplikasi Jadwal Recurring
    test('7. Menekan centang berulang kali tidak membuat duplikasi jadwal baru', () {
      final item = JadwalItem(
        id: 'j_no_duplicate',
        judul: 'Lari 10 menit',
        tanggal: DateTime(2026, 11, 16, 8, 0),
        ulangi: true,
        frekuensi: FrekuensiUlang.sekaliSehari,
      );
      service.tambahJadwal(item);

      // Centang selesai -> buat 1 penerus
      service.toggleSelesai(item);
      expect(service.semuaJadwal.length, equals(2));

      // Batal centang
      final itemSelesai = service.semuaJadwal.firstWhere((j) => j.id == 'j_no_duplicate');
      service.toggleSelesai(itemSelesai);
      expect(service.semuaJadwal.firstWhere((j) => j.id == 'j_no_duplicate').selesai, isFalse);

      // Centang lagi -> tidak boleh membuat dobel
      final itemBelum = service.semuaJadwal.firstWhere((j) => j.id == 'j_no_duplicate');
      service.toggleSelesai(itemBelum);
      expect(service.semuaJadwal.length, equals(2)); // Tetap 2, tidak jadi 3
    });

    // 8. Statistik Dinamis (Terlambat & Tersisa)
    test('8. Jumlah terlambat dan tersisa minggu ini terhitung akurat sesuai data', () {
      final now = DateTime.now();
      // 1 jadwal kemarin belum selesai (terlambat)
      service.tambahJadwal(JadwalItem(
        id: 'st_1',
        judul: 'Terlambat 1',
        tanggal: now.subtract(const Duration(days: 1)),
        selesai: false,
      ));

      // 1 jadwal kemarin sudah selesai (bukan terlambat)
      service.tambahJadwal(JadwalItem(
        id: 'st_2',
        judul: 'Selesai kemarin',
        tanggal: now.subtract(const Duration(days: 1)),
        selesai: true,
      ));

      // 2 jadwal hari ini belum selesai
      service.tambahJadwal(JadwalItem(
        id: 'st_3',
        judul: 'Hari ini 1',
        tanggal: now,
        selesai: false,
      ));
      service.tambahJadwal(JadwalItem(
        id: 'st_4',
        judul: 'Hari ini 2',
        tanggal: now,
        selesai: false,
      ));

      expect(service.jumlahTerlambat, equals(1));
      expect(service.jumlahBelumSelesai, equals(3));
    });
  });
}
