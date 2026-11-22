import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';
import '../../widgets/mini_line_chart.dart';
import '../sesi/widgets/osm_tracking_map.dart';
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
    final double cardAspectRatio = screenWidth < 360 ? 1.3 : 1.48;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0077E6),
                  size: 17,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Detail Aktivitas',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Header Jenis & Waktu Aktivitas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.jenis == 'Berjalan'
                          ? Icons.directions_walk_rounded
                          : Icons.directions_run_rounded,
                      color: const Color(0xFF0077E6),
                      size: 25,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.tanggal.day} ${_namaBulan(item.tanggal.month)} ${item.tanggal.year} • ${item.tanggal.hour.toString().padLeft(2, '0')}.${item.tanggal.minute.toString().padLeft(2, '0')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Peta Rute Perjalanan OpenStreetMap (Jika Tersedia)
            if (item.rutePoints.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: OsmTrackingMap(
                  rutePoints: item.rutePoints,
                  posisiAwal: item.rutePoints.first,
                  posisiSaatIni: item.rutePoints.last,
                  followUser: false,
                  isReadOnly: true,
                  gpsStatusText: 'Rute Aktivitas (${item.rutePoints.length} titik)',
                  gpsStatusColor: const Color(0xFF0077E6),
                  onToggleFollow: () {},
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Grid Kartu Statistik
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
                  const Color(0xFF0077E6),
                  const Color(0xFFDBEAFE),
                  'Jarak Tempuh',
                  '${item.jarakKm.toStringAsFixed(2)} km',
                ),
                _kartuStat(
                  Icons.local_fire_department_rounded,
                  const Color(0xFFF59E0B),
                  const Color(0xFFFEF3C7),
                  'Estimasi Kalori',
                  '${item.kalori} kcal',
                ),
                _kartuStat(
                  Icons.access_time_rounded,
                  const Color(0xFF0284C7),
                  const Color(0xFFE0F2FE),
                  'Durasi',
                  item.durasiHms,
                ),
                _kartuStat(
                  Icons.directions_walk_rounded,
                  const Color(0xFF0EA5E9),
                  const Color(0xFFE0F2FE),
                  'Jumlah Langkah',
                  item.sensorLangkahTersedia
                      ? '${item.langkah}'
                      : 'Tidak tersedia',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Grafik Kecepatan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart_rounded,
                          size: 18, color: Color(0xFF0077E6)),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Grafik Kecepatan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        '${item.kecepatanRataRataKmh.toStringAsFixed(1)} km/jam',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0077E6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MiniLineChart(nilai: item.kecepatanSeries),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tombol Unduh Riwayat
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => UnduhRiwayatScreen(item: item)),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text(
                  'Unduh Laporan Aktivitas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kartuStat(
      IconData icon, Color color, Color bg, String label, String nilai) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  nilai,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}