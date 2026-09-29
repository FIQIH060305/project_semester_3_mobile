import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';
import '../../widgets/button_navbar.dart';
import '../../widgets/jadwal_checklist_tile.dart';
import 'tambah_tugas_screen.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  late List<JadwalItem> semuaJadwal;

  @override
  void initState() {
    super.initState();
    semuaJadwal = dataDummyJadwal();
  }

  void _toggleSelesai(JadwalItem item) {
    setState(() => item.selesai = !item.selesai);
  }

  Future<void> _bukaFormTambah() async {
    final hasil = await Navigator.of(context).push<JadwalItem>(
      MaterialPageRoute(builder: (_) => const TambahTugasScreen()),
    );
    if (hasil != null) {
      setState(() => semuaJadwal.add(hasil));
    }
  }

  @override
  Widget build(BuildContext context) {
    final terlambat = semuaJadwal.where((j) => j.kategoriWaktu == 'Terlambat').toList();
    final besok = semuaJadwal.where((j) => j.kategoriWaktu == 'Besok').toList();
    final mingguDepan = semuaJadwal.where((j) => j.kategoriWaktu == 'Minggu depan').toList();
    final hariIni = semuaJadwal.where((j) => j.kategoriWaktu == 'Hari ini').toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        elevation: 0,
        title: const Text('Buat jadwalmu sendiri', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        // Tombol kembali otomatis muncul kalau layar ini didorong (push),
        // dan otomatis hilang kalau dibuka lewat bottom nav.
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (terlambat.isNotEmpty) ...[
              const _JudulSeksi(teks: 'Terlambat', warna: AppColors.statRose),
              ...terlambat.map((j) => JadwalChecklistTile(
                    item: j,
                    terlambat: true,
                    onToggle: () => _toggleSelesai(j),
                  )),
              const SizedBox(height: 12),
            ],
            if (hariIni.isNotEmpty) ...[
              const _JudulSeksi(teks: 'Hari ini', warna: AppColors.brand),
              ...hariIni.map((j) => JadwalChecklistTile(item: j, onToggle: () => _toggleSelesai(j))),
              const SizedBox(height: 12),
            ],
            if (besok.isNotEmpty) ...[
              const _JudulSeksi(teks: 'Besok', warna: AppColors.brand),
              ...besok.map((j) => JadwalChecklistTile(item: j, onToggle: () => _toggleSelesai(j))),
              const SizedBox(height: 12),
            ],
            if (mingguDepan.isNotEmpty) ...[
              const _JudulSeksi(teks: 'Minggu depan', warna: AppColors.brand),
              ...mingguDepan.map((j) => JadwalChecklistTile(item: j, onToggle: () => _toggleSelesai(j))),
            ],
            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brand,
        onPressed: _bukaFormTambah,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}

class _JudulSeksi extends StatelessWidget {
  final String teks;
  final Color warna;
  const _JudulSeksi({required this.teks, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        teks,
        style: TextStyle(color: warna, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}