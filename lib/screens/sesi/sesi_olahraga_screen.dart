import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../riwayat/riwayat_olahraga_screen.dart';

class SesiOlahragaScreen extends StatelessWidget {
  const SesiOlahragaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final riwayatTerbaru = dataDummyRiwayat().take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text('Sesi Olahraga', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Hitung Kalori & jarakMu disini', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Pilih target dan jenis aktivitasmu hari ini untuk mulai melangkah.',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('Pilih aksi olahraga', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            _kartuAksi(
              context,
              icon: Icons.directions_walk_rounded,
              judul: 'Berjalan',
              deskripsi: 'Olahraga ringan dengan berjalan kaki untuk menjaga kebugaran jantung dan membakar lemak stabil.',
              tag1: 'Pace santai 4-6 km/jam',
              tag2: 'Zona 3-4 Denyut',
              estimasi: 'Est. 140 Kkal/30m',
            ),
            const SizedBox(height: 12),
            _kartuAksi(
              context,
              icon: Icons.directions_run_rounded,
              judul: 'Berlari',
              deskripsi: 'Olahraga lari sesuai kemampuan dan target pembakaran kalori optimal untuk memperkuat stamina tubuh.',
              tag1: 'Fokus Kekuatan & Daya tahan',
              tag2: 'Zona 3-4 Denyut',
              estimasi: 'Est. 320 Kkal/10m',
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Sesi', style: TextStyle(fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RiwayatOlahragaScreen()),
                  ),
                  child: const Text('Lihat Semua', style: TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...riwayatTerbaru.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${r.jenis} • ${r.waktuMenit} menit', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Text('${r.jarakKm} km   ${r.langkah} langkah', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _kartuAksi(BuildContext context, {
    required IconData icon,
    required String judul,
    required String deskripsi,
    required String tag1,
    required String tag2,
    required String estimasi,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.brand.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.badgeBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(judul, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 8),
          Text(deskripsi, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _tagKecil(tag1, AppColors.statGreenBg, AppColors.statGreen),
              _tagKecil(tag2, AppColors.statRoseBg, AppColors.statRose),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(estimasi, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sesi $judul dimulai (dummy, belum ada timer aktif).')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Mulai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagKecil(String teks, Color bg, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(teks, style: TextStyle(color: warna, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}