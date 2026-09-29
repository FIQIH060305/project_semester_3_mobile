import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/mini_line_chart.dart';
import 'unduh_riwayat_screen.dart';

class DetailRiwayatScreen extends StatelessWidget {
  final RiwayatItem item;
  const DetailRiwayatScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text('Detail Riwayat', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: AppColors.badgeBg, borderRadius: BorderRadius.circular(14)),
                    child: Icon(item.jenis == 'Berjalan' ? Icons.directions_walk_rounded : Icons.directions_run_rounded, color: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.jenis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${item.tanggal.day} September ${item.tanggal.year} • ${item.tanggal.hour.toString().padLeft(2, '0')}.${item.tanggal.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _kartuStat(Icons.route_rounded, AppColors.statRose, AppColors.statRoseBg, 'Jarak', '${item.jarakKm} km'),
                _kartuStat(Icons.local_fire_department_rounded, AppColors.statAmber, AppColors.statAmberBg, 'Kalori', '${item.kalori} kal'),
                _kartuStat(Icons.access_time_rounded, AppColors.statGreen, AppColors.statGreenBg, 'Waktu', item.waktuFormat),
                _kartuStat(Icons.directions_walk_rounded, AppColors.brand, AppColors.badgeBg, 'Langkah', '${item.langkah}'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.show_chart_rounded, size: 16, color: AppColors.brand),
                    SizedBox(width: 6),
                    Text('Grafik Kecepatan', style: TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  MiniLineChart(nilai: item.kecepatanSeries),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => UnduhRiwayatScreen(item: item)),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text('Unduh Riwayat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _kartuStat(IconData icon, Color color, Color bg, String label, String nilai) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(nilai, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}