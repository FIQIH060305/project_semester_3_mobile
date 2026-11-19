import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gerak_animations.dart';
import '../main_navigation_screen.dart';
import 'detail_riwayat_screen.dart';

class RiwayatOlahragaScreen extends StatefulWidget {
  final bool showBottomNav;
  const RiwayatOlahragaScreen({super.key, this.showBottomNav = true});

  @override
  State<RiwayatOlahragaScreen> createState() => _RiwayatOlahragaScreenState();
}

class _RiwayatOlahragaScreenState extends State<RiwayatOlahragaScreen> {
  String filter = 'Semua';
  List<RiwayatItem> semuaRiwayat = [];
  bool _isLoading = true;

  static const List<String> _namaBulan = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _loadRiwayatDariServer();
  }

  Future<void> _loadRiwayatDariServer() async {
    setState(() => _isLoading = true);
    try {
      final rawList = await AuthService.instance.fetchRiwayatOlahraga();
      if (!mounted) return;

      final mapped = rawList.map((row) {
        final jenisRaw = (row['jenis_olahraga'] ?? 'Berlari').toString();
        final jenisNormalized = jenisRaw.toLowerCase().contains('jalan')
            ? 'Berjalan'
            : 'Berlari';

        final jarak = double.tryParse(row['jarak_km']?.toString() ?? '0') ?? 0.0;
        final durasiDetik =
            int.tryParse(row['durasi_detik']?.toString() ?? '0') ?? 0;
        final langkah =
            int.tryParse(row['jumlah_langkah']?.toString() ?? '0') ?? 0;
        final kalori =
            (double.tryParse(row['kalori_terbakar']?.toString() ?? '0') ?? 0.0)
                .round();

        DateTime tanggal = DateTime.now();
        final createdStr =
            (row['created_at'] ?? row['tanggal'] ?? '').toString();
        if (createdStr.isNotEmpty) {
          tanggal = DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now();
        }

        final menit = (durasiDetik / 60).round().clamp(1, 9999);
        final avgSpeedKmh = durasiDetik > 0
            ? (jarak / (durasiDetik / 3600.0)).clamp(1.0, 30.0)
            : (jenisNormalized == 'Berlari' ? 8.5 : 4.5);

        final series = <double>[
          double.parse((avgSpeedKmh * 0.75).toStringAsFixed(1)),
          double.parse((avgSpeedKmh * 0.90).toStringAsFixed(1)),
          double.parse((avgSpeedKmh * 1.05).toStringAsFixed(1)),
          double.parse((avgSpeedKmh * 1.15).toStringAsFixed(1)),
          double.parse((avgSpeedKmh * 1.10).toStringAsFixed(1)),
          double.parse((avgSpeedKmh * 0.95).toStringAsFixed(1)),
          double.parse((avgSpeedKmh * 0.85).toStringAsFixed(1)),
        ];

        return RiwayatItem(
          id: (row['id_aktivitas'] ?? row['id'] ?? '').toString(),
          jenis: jenisNormalized,
          tanggal: tanggal,
          jarakKm: double.parse(jarak.toStringAsFixed(2)),
          kalori: kalori,
          waktuMenit: menit,
          langkah: langkah,
          kecepatanSeries: series,
        );
      }).toList();

      setState(() {
        semuaRiwayat = mapped;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(DateTime dt) {
    final bln = (dt.month >= 1 && dt.month <= 12) ? _namaBulan[dt.month] : 'Bul';
    final jam = dt.hour.toString().padLeft(2, '0');
    final mnt = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $bln ${dt.year} • $jam:$mnt';
  }

  @override
  Widget build(BuildContext context) {
    final list = filter == 'Semua'
        ? semuaRiwayat
        : semuaRiwayat.where((r) => r.jenis == filter).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            final nav = MainNavigationController.of(context);
            if (nav != null) {
              nav.switchTab(0);
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.brand,
            size: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Riwayat Olahraga',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadRiwayatDariServer,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.brand),
            tooltip: 'Muat Ulang Riwayat',
          ),
        ],
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: aktif ? AppColors.brand : AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: aktif ? Colors.white : AppColors.brand,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRiwayatDariServer,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Icon(
                                Icons.directions_run_rounded,
                                size: 64,
                                color: AppColors.brand.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Belum ada riwayat aktivitas',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Mulai sesi jalan atau lari pada menu Tracking untuk mencatat aktivitas pertamamu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final r = list[i];
                              return GerakEntrance(
                                delayMs: (i * 50).clamp(0, 350),
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailRiwayatScreen(item: r),
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: AppColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.badgeBg,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            r.jenis == 'Berjalan'
                                                ? Icons.directions_walk_rounded
                                                : Icons.directions_run_rounded,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.jenis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatTanggal(r.tanggal),
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textGrey,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${r.jarakKm} km  •  🔥 ${r.kalori} kal  •  ⏱ ${r.waktuFormat}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: AppColors.brand,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNavBar(currentIndex: 3) : null,
    );
  }
}