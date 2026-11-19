import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';
import '../../widgets/mini_line_chart.dart';
import 'unduh_riwayat_screen.dart';

class DetailRiwayatScreen extends StatelessWidget {
  final RiwayatItem item;
  const DetailRiwayatScreen({super.key, required this.item});

  String _namaBulan(int bulan) {
    const daftarBulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (bulan >= 1 && bulan <= 12) return daftarBulan[bulan];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Sesuaikan rasio kartu agar tetap muat dan tidak overflow di HP berlayar sempit
    final double cardAspectRatio = screenWidth < 360 ? 1.3 : 1.45;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Detail Riwayat',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Jenis & Waktu Aktivitas
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.badgeBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.jenis == 'Berjalan'
                          ? Icons.directions_walk_rounded
                          : Icons.directions_run_rounded,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.jenis,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.tanggal.day} ${_namaBulan(item.tanggal.month)} ${item.tanggal.year} • ${item.tanggal.hour.toString().padLeft(2, '0')}.${item.tanggal.minute.toString().padLeft(2, '0')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Grid Kartu Statistik (Responsif tanpa overflow)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cardAspectRatio,
              children: [
                _kartuStat(
                  Icons.route_rounded,
                  AppColors.statRose,
                  AppColors.statRoseBg,
                  'Jarak',
                  '${item.jarakKm.toStringAsFixed(2)} km',
                ),
                _kartuStat(
                  Icons.local_fire_department_rounded,
                  AppColors.statAmber,
                  AppColors.statAmberBg,
                  'Kalori',
                  '${item.kalori} kal',
                ),
                _kartuStat(
                  Icons.access_time_rounded,
                  AppColors.statGreen,
                  AppColors.statGreenBg,
                  'Waktu',
                  item.waktuFormat,
                ),
                _kartuStat(
                  Icons.directions_walk_rounded,
                  AppColors.brand,
                  AppColors.badgeBg,
                  'Langkah',
                  '${item.langkah}',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Grafik Kecepatan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart_rounded, size: 16, color: AppColors.brand),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Grafik Kecepatan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MiniLineChart(nilai: item.kecepatanSeries),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Unduh Riwayat
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => UnduhRiwayatScreen(item: item)),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Unduh Riwayat',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _kartuStat(IconData icon, Color color, Color bg, String label, String nilai) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  nilai,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}