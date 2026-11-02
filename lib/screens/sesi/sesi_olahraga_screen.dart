import 'package:flutter/material.dart';
import '../../models/riwayat_item.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../riwayat/riwayat_olahraga_screen.dart';
import 'mulai_olahraga_screen.dart';
import 'ringkasan_sesi_screen.dart';
import 'widgets/exercise_illustrations.dart';

class SesiOlahragaScreen extends StatelessWidget {
  const SesiOlahragaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Sesi Olahraga',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Image.asset(
                'assets/images/logo_gerak.png',
                height: 32,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: [
            // Subtitle Title with Colored Words
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                children: [
                  TextSpan(text: 'Hitung '),
                  TextSpan(
                    text: 'Kalori',
                    style: TextStyle(color: Color(0xFF0077E6)),
                  ),
                  TextSpan(text: ' & '),
                  TextSpan(
                    text: 'jarakMu',
                    style: TextStyle(color: Color(0xFFF59E0B)),
                  ),
                  TextSpan(text: ' disini'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih target dan jenis aktivitasmu hari ini untuk mulai melangkah.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Section: Pilih Olahraga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih olahraga',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Pilihan Terbuka',
                    style: TextStyle(
                      color: Color(0xFF0077E6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. Card Berjalan
            _buildOlahragaCard(
              context,
              illustration: const WalkingIllustrationWidget(width: 68, height: 82),
              judul: 'Berjalan',
              deskripsi: 'Olahraga ringan dengan berjalan kaki untuk menjaga kebugaran jantung dan membakar lemak stabil.',
              chip1: 'Pace santai 4 - 5 km/jam',
              chip1Bg: const Color(0xFFDCEEFD),
              chip1Text: const Color(0xFF1D4ED8),
              chip2: 'Zona 3-4 Denyut',
              chip2Bg: const Color(0xFFFFE4E6),
              chip2Text: const Color(0xFFBE185D),
              estimasi: 'Est. 140 Kkal/30m',
              onMulai: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MulaiOlahragaScreen(
                      jenisOlahraga: 'Berjalan',
                      targetSplit: "5’45” / km",
                      jarakTarget: "3.0 KM",
                      estKalori: "140 cal",
                      estDurasi: "30 mnt",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. Card Berlari
            _buildOlahragaCard(
              context,
              illustration: const RunningIllustrationWidget(width: 68, height: 82),
              judul: 'Berlari',
              deskripsi: 'olahraga lari sesuai kemampuan dan target pembakaran kalori optimal untuk memperkuat stamina tubuh',
              chip1: 'Fokus Kekuatan & Daya tahan',
              chip1Bg: const Color(0xFFDCFCE7),
              chip1Text: const Color(0xFF15803D),
              chip2: 'Zona 3 - 4 Denyut',
              chip2Bg: const Color(0xFFFFE4E6),
              chip2Text: const Color(0xFFBE185D),
              estimasi: 'Est. 320 Kkal/10m',
              onMulai: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MulaiOlahragaScreen(
                      jenisOlahraga: 'Berlari',
                      targetSplit: "5’35” / km",
                      jarakTarget: "5.0 KM",
                      estKalori: "321 cal",
                      estDurasi: "30 mnt",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section: Riwayat Sesi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Sesi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RiwayatOlahragaScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFF0077E6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daftar Riwayat Sesi Terbaru
            ...dataDummyRiwayat().take(2).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRiwayatCard(
                  context,
                  judul: '${item.jenis} · ${item.waktuFormat}',
                  detail: 'Hari ini ${item.jarakKm.toString().replaceAll('.', ',')} km ${item.langkah} langkah',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RingkasanSesiScreen(
                          jenisOlahraga: item.jenis,
                          durasiMenit: '${item.waktuMenit}',
                          jarakKm: item.jarakKm.toString().replaceAll('.', ','),
                          langkah: item.langkah.toString(),
                          kalori: '${item.kalori}',
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildOlahragaCard(
    BuildContext context, {
    required Widget illustration,
    required String judul,
    required String deskripsi,
    required String chip1,
    required Color chip1Bg,
    required Color chip1Text,
    required String chip2,
    required Color chip2Bg,
    required Color chip2Text,
    required String estimasi,
    required VoidCallback onMulai,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration + Title & Desc
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              illustration,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: chip1Bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  chip1,
                  style: TextStyle(
                    color: chip1Text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: chip2Bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  chip2,
                  style: TextStyle(
                    color: chip2Text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: Estimasi & Mulai Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                estimasi,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              ElevatedButton(
                onPressed: onMulai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077E6),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Mulai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(
    BuildContext context, {
    required String judul,
    required String detail,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBFDBFE),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
