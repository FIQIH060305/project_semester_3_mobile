import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';
import '../../widgets/button_navbar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/jadwal_checklist_tile.dart';
import '../../widgets/mini_line_chart.dart';
import '../jadwal/jadwal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final namaPengguna = 'Robit';
  late List<JadwalItem> latihanHariIni;

  final beratMingguan = [92.0, 91.5, 91.0, 90.5, 90.5];

  @override
  void initState() {
    super.initState();
    // Ambil 3 jadwal hari ini saja untuk ditampilkan di kartu ringkasan
    latihanHariIni = dataDummyJadwal().take(3).toList();
  }

  void _toggleSelesai(JadwalItem item) {
    setState(() => item.selesai = !item.selesai);
  }

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
              Text('Hai, $namaPengguna 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Semangat jaga kesehatan!',
                  style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),

              // Kartu Latihan Hari Ini
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Latihan hari ini',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const JadwalScreen()),
                            );
                          },
                          child: const Text('Lihat semua',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...latihanHariIni.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: JadwalChecklistTile(
                            item: item,
                            onToggle: () => _toggleSelesai(item),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu statistik langkah & kalori
              Row(
                children: [
                  StatCard(
                    icon: Icons.directions_walk_rounded,
                    iconColor: AppColors.statGreen,
                    background: AppColors.statGreenBg,
                    label: 'Langkah',
                    nilai: 1000,
                    target: 10000,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.statAmber,
                    background: AppColors.statAmberBg,
                    label: 'Kalori',
                    nilai: 1000,
                    target: 10000,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu berat badan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Berat badan',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const Text('-1,5 kg minggu ini',
                            style: TextStyle(
                                color: AppColors.statGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${beratMingguan.last} kg',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        const Text('Target 75 kg',
                            style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
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