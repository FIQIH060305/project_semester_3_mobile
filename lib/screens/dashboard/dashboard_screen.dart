import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/mini_line_chart.dart';
import '../jadwal/jadwal_screen.dart';
import '../sesi/sesi_olahraga_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final namaPengguna = 'Robit';
  final streakHari = 10;
  late List<JadwalItem> latihanHariIni;
  final beratMingguan = [92.0, 91.5, 91.0, 90.5, 90.5];

  @override
  void initState() {
    super.initState();
    latihanHariIni = dataDummyJadwal().take(3).toList();
  }

  void _toggleSelesai(JadwalItem item) => setState(() => item.selesai = !item.selesai);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hai, $namaPengguna 👋',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Semangat jaga kesehatan!', style: TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.statAmberBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('🔥 $streakHari Hari',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu "Fokus Pagi"
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('FOKUS PAGI',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Bersiap capai 5KM Pertamamu!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Header Latihan Hari Ini + tombol mulai sesi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Latihan Hari Ini', style: TextStyle(fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SesiOlahragaScreen()),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, color: AppColors.brand, size: 18),
                        SizedBox(width: 4),
                        Text('Mulai sesi', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: latihanHariIni.map((item) {
                    final badgeBg = item.selesai ? AppColors.badgeDoneBg : AppColors.badgeBg;
                    final badgeText = item.selesai ? AppColors.badgeDoneText : AppColors.badgeText;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleSelesai(item),
                            child: Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.selesai ? AppColors.brand : Colors.white,
                                border: Border.all(color: item.selesai ? AppColors.brand : AppColors.border, width: 1.5),
                              ),
                              child: item.selesai
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.judul,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: item.selesai ? TextDecoration.lineThrough : null,
                                      color: item.selesai ? AppColors.textGrey : AppColors.textDark,
                                    )),
                                Text('Hari ini, ${item.tanggal.hour.toString().padLeft(2, '0')}.${item.tanggal.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(item.labelBadge, style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  StatCard(icon: Icons.directions_walk_rounded, iconColor: AppColors.statGreen, background: AppColors.statGreenBg, label: 'Langkah', nilai: 1000, target: 10000),
                  const SizedBox(width: 12),
                  StatCard(icon: Icons.local_fire_department_rounded, iconColor: AppColors.statAmber, background: AppColors.statAmberBg, label: 'Kalori', nilai: 1000, target: 10000),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Berat badan', style: TextStyle(fontWeight: FontWeight.w700)),
                        const Text('-1,5 kg minggu ini', style: TextStyle(color: AppColors.statGreen, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${beratMingguan.last} kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        const Text('Target 75 kg', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MiniLineChart(nilai: beratMingguan),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 minggu lalu', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        Text('Sekarang', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}