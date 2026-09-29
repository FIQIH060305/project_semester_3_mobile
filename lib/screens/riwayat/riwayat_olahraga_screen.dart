import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'detail_riwayat_screen.dart';

class RiwayatOlahragaScreen extends StatefulWidget {
  const RiwayatOlahragaScreen({super.key});

  @override
  State<RiwayatOlahragaScreen> createState() => _RiwayatOlahragaScreenState();
}

class _RiwayatOlahragaScreenState extends State<RiwayatOlahragaScreen> {
  String filter = 'Semua';
  late List<RiwayatItem> semuaRiwayat;

  @override
  void initState() {
    super.initState();
    semuaRiwayat = dataDummyRiwayat();
  }

  @override
  Widget build(BuildContext context) {
    final list = filter == 'Semua' ? semuaRiwayat : semuaRiwayat.where((r) => r.jenis == filter).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text('Riwayat Olahraga', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: ['Semua', 'Berjalan', 'Berlari'].map((f) {
                  final aktif = filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: aktif ? AppColors.brand : AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f, style: TextStyle(color: aktif ? Colors.white : AppColors.brand, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final r = list[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DetailRiwayatScreen(item: r)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: AppColors.badgeBg, borderRadius: BorderRadius.circular(12)),
                            child: Icon(r.jenis == 'Berjalan' ? Icons.directions_walk_rounded : Icons.directions_run_rounded, color: AppColors.brand),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.jenis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('${r.tanggal.day} Sep ${r.tanggal.year} • ${r.tanggal.hour.toString().padLeft(2, '0')}:${r.tanggal.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                const SizedBox(height: 4),
                                Text('${r.jarakKm} km   🔥 ${r.kalori} kal   ⏱ ${r.waktuFormat}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brand),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}