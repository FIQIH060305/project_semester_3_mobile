import 'package:flutter/material.dart';
import '../../models/riwayat_item.dart';
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
  late final RiwayatService _riwayatService;

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
    _riwayatService = RiwayatService.instance;
    _riwayatService.initialize(forceRefresh: true);
    _riwayatService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _riwayatService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _formatTanggal(DateTime dt) {
    final bln = (dt.month >= 1 && dt.month <= 12) ? _namaBulan[dt.month] : 'Bul';
    final jam = dt.hour.toString().padLeft(2, '0');
    final mnt = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $bln ${dt.year} • $jam:$mnt';
  }

  @override
  Widget build(BuildContext context) {
    final semua = _riwayatService.semuaRiwayat;
    final list = filter == 'Semua'
        ? semua
        : semua.where((r) => r.jenis == filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Modern ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final nav = MainNavigationController.of(context);
                        if (nav != null) {
                          nav.switchTab(0);
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .pushReplacementNamed('/dashboard');
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF0077E6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Aktivitas',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Catatan seluruh sesi jalan & larimu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _riwayatService.syncFromServer,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF0077E6)),
                    tooltip: 'Muat Ulang Riwayat',
                  ),
                ],
              ),
            ),

            // ── Kartu Ringkasan Akumulasi Aktivitas ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    _buildMiniRecap(
                      'Total Sesi',
                      '${_riwayatService.totalAktivitas}',
                      const Color(0xFF0077E6),
                    ),
                    _buildDivider(),
                    _buildMiniRecap(
                      'Total Jarak',
                      '${_riwayatService.totalJarakKm.toStringAsFixed(1)} km',
                      const Color(0xFF0284C7),
                    ),
                    _buildDivider(),
                    _buildMiniRecap(
                      'Total Durasi',
                      '${_riwayatService.totalDurasiMenit} mnt',
                      const Color(0xFF10B981),
                    ),
                    _buildDivider(),
                    _buildMiniRecap(
                      'Est. Kalori',
                      '${_riwayatService.totalKalori} kcal',
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ),

            // ── Filter Jenis Aktivitas ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
              child: Row(
                children: ['Semua', 'Berjalan', 'Berlari'].map((f) {
                  final aktif = filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: aktif
                              ? const Color(0xFF0077E6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: aktif
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0077E6)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: aktif
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Daftar Riwayat ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0077E6),
                onRefresh: _riwayatService.syncFromServer,
                child: _riwayatService.isLoading && list.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0077E6),
                        ),
                      )
                    : list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.directions_run_rounded,
                                        size: 30,
                                        color: Color(0xFF0077E6),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Belum ada riwayat aktivitas',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Mulai sesi jalan kaki atau berlari pada menu Tracking untuk mencatat aktivitas pertamamu.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final r = list[i];
                              final isJalan = r.jenis == 'Berjalan';

                              return GerakEntrance(
                                delayMs: (i * 45).clamp(0, 320),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailRiwayatScreen(item: r),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0F172A)
                                                  .withValues(alpha: 0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: isJalan
                                                    ? const Color(0xFFE0F2FE)
                                                    : const Color(0xFFDBEAFE),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                isJalan
                                                    ? Icons
                                                        .directions_walk_rounded
                                                    : Icons
                                                        .directions_run_rounded,
                                                color: const Color(0xFF0077E6),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        r.jenis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 15,
                                                          color:
                                                              Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      if (r.rutePoints
                                                          .isNotEmpty) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 7,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFEFF6FF),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: const Text(
                                                            'Rute GPS',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Color(
                                                                  0xFF0077E6),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _formatTanggal(r.tanggal),
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      _chipInfo(
                                                        Icons.route_rounded,
                                                        '${r.jarakKm.toStringAsFixed(2)} km',
                                                        const Color(0xFF0077E6),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _chipInfo(
                                                        Icons.timer_outlined,
                                                        r.waktuFormat,
                                                        const Color(0xFF0284C7),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _chipInfo(
                                                        Icons
                                                            .local_fire_department_rounded,
                                                        '${r.kalori} kcal',
                                                        const Color(0xFFF59E0B),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ],
                                        ),
                                      ),
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

  Widget _buildMiniRecap(String label, String value, Color accent) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 26,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _chipInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}