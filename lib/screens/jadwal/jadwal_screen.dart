import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';
import '../../widgets/bottom_nav_bar.dart';
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

  void _toggleSelesai(JadwalItem item) => setState(() => item.selesai = !item.selesai);

  Future<void> _bukaFormTambah() async {
    final hasil = await Navigator.of(context).push<JadwalItem>(
      MaterialPageRoute(builder: (_) => const TambahTugasScreen()),
    );
    if (hasil != null) setState(() => semuaJadwal.add(hasil));
  }

  @override
  Widget build(BuildContext context) {
    final terlambat = semuaJadwal.where((j) => j.kategoriWaktu == 'Terlambat').toList();
    final hariIni = semuaJadwal.where((j) => j.kategoriWaktu == 'Hari ini').toList();
    final besok = semuaJadwal.where((j) => j.kategoriWaktu == 'Besok').toList();
    final mingguDepan = semuaJadwal.where((j) => j.kategoriWaktu == 'Minggu depan').toList();
    final tersisaMingguIni = semuaJadwal.where((j) => !j.selesai).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        elevation: 0,
        title: const Text('Buat jadwalmu sendiri', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.statRoseBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${terlambat.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.statRose, size: 18),
                                ],
                              ),
                              const Text('Perlu dikejar', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                              const Text('latihan terlewat', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.badgeBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$tersisaMingguIni', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                  const Icon(Icons.event_note_rounded, color: AppColors.brand, size: 18),
                                ],
                              ),
                              const Text('Tersisa minggu ini', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                              const Text('latihan tersisa', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (terlambat.isNotEmpty) ...[
                    const _JudulSeksi(teks: 'Terlambat', warna: AppColors.statRose),
                    ...terlambat.map((j) => JadwalChecklistTile(item: j, terlambat: true, onToggle: () => _toggleSelesai(j))),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _bukaFormTambah,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah latihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      child: Text(teks, style: TextStyle(color: warna, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}