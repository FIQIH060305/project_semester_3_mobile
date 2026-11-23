import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/jadwal_item.dart';
import '../../services/jadwal_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gerak_animations.dart';
import 'tambah_tugas_screen.dart';

class JadwalScreen extends StatefulWidget {
  final bool showBottomNav;
  const JadwalScreen({super.key, this.showBottomNav = true});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  late final JadwalService _service;

  @override
  void initState() {
    super.initState();
    _service = JadwalService.instance;
    _service.initialize();
    _service.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS & NAVIGASI HALUS
  // ═══════════════════════════════════════════════════════════════

  Route<JadwalItem> _createSmoothRoute(Widget page) {
    return PageRouteBuilder<JadwalItem>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _toggleSelesai(JadwalItem item) {
    HapticFeedback.lightImpact();
    _service.toggleSelesai(item);
  }

  Future<void> _bukaFormTambah() async {
    final hasil = await Navigator.of(context).push<JadwalItem>(
      _createSmoothRoute(const TambahTugasScreen()),
    );
    if (hasil != null) {
      await _service.tambahJadwal(hasil);
    }
  }

  Future<void> _bukaFormEdit(JadwalItem item) async {
    final hasil = await Navigator.of(context).push<JadwalItem>(
      _createSmoothRoute(TambahTugasScreen(editItem: item)),
    );
    if (hasil != null) {
      await _service.gantiJadwal(item.id, hasil);
    }
  }

  Future<void> _konfirmasiHapus(JadwalItem item) async {
    final hapus = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Jadwal',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Apakah kamu yakin ingin menghapus jadwal '),
                  TextSpan(
                    text: '"${item.judul}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            if (item.ulangi && item.frekuensi != FrekuensiUlang.tidakUlang)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pengulangan otomatis untuk jadwal ini juga akan dihentikan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
            child: const Text(
              'Ya, Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (hapus == true) {
      await _service.hapusJadwal(item.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Jadwal "${item.judul}" berhasil dihapus.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0077E6),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _onLongPress(JadwalItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(item.tanggal)} • Pukul ${item.jamFormatted}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.ulangi && item.frekuensi != FrekuensiUlang.tidakUlang) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.frekuensi == FrekuensiUlang.sekaliSehari
                          ? 'Berulang setiap hari'
                          : 'Berulang setiap minggu',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Color(0xFF0077E6), size: 20),
                  ),
                  title: const Text(
                    'Edit Jadwal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: const Text(
                    'Ubah nama latihan, tanggal, jam, atau pengulangan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _bukaFormEdit(item);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626), size: 20),
                  ),
                  title: const Text(
                    'Hapus Jadwal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  subtitle: const Text(
                    'Hapus jadwal latihan ini dari daftar',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _konfirmasiHapus(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final terlambat = _service.terlambat;
    final hariIni = _service.hariIni;
    final besok = _service.besok;
    final mingguDepan = _service.mingguDepan;
    final riwayatSelesai = _service.riwayatSelesai;

    final hasNoItems = terlambat.isEmpty &&
        hariIni.isEmpty &&
        besok.isEmpty &&
        mingguDepan.isEmpty &&
        riwayatSelesai.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. HEADER MINIMALIS & PROPORSIONAL ─────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              color: const Color(0xFFF7FAFF),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Jadwalmu Sendiri',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Atur target latihan harian & mingguanmu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_service.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0077E6),
                      ),
                    ),
                ],
              ),
            ),

            // ── 2. KONTEN UTAMA ────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0077E6),
                onRefresh: _service.syncFromServer,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: [
                    // ── Kartu Ringkasan Jadwal ────────────────────
                    GerakEntrance(
                      delayMs: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryStatCard(
                              title: 'Perlu dikejar',
                              count: _service.jumlahTerlambat,
                              subtitle: 'latihan terlewat',
                              icon: Icons.warning_amber_rounded,
                              accentColor: const Color(0xFFEF4444),
                              iconBgColor: const Color(0xFFFEE2E2),
                              cardTintColor: const Color(0xFFFFFBFB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryStatCard(
                              title: 'Tersisa minggu ini',
                              count: _service.jumlahTersisaMingguIni,
                              subtitle: 'latihan tersisa',
                              icon: Icons.event_available_rounded,
                              accentColor: const Color(0xFF0077E6),
                              iconBgColor: const Color(0xFFDBEAFE),
                              cardTintColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Petunjuk interaksi singkat
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 14,
                          color: const Color(0xFF64748B).withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Ketuk kotak untuk menandai selesai • Tekan lama kartu untuk edit/hapus',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Kelompok: Terlambat ───────────────────────
                    if (terlambat.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Terlambat',
                        count: terlambat.length,
                        color: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEE2E2),
                      ),
                      ...List.generate(terlambat.length, (i) {
                        final j = terlambat[i];
                        return GerakEntrance(
                          delayMs: 60 + (i * 40),
                          child: _ModernJadwalCard(
                            item: j,
                            tipe: _JadwalVisualType.terlambat,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                    ],

                    // ── Kelompok: Hari ini ────────────────────────
                    if (hariIni.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Hari ini',
                        count: hariIni.length,
                        color: const Color(0xFF0077E6),
                        bgColor: const Color(0xFFDBEAFE),
                      ),
                      ...List.generate(hariIni.length, (i) {
                        final j = hariIni[i];
                        return GerakEntrance(
                          delayMs: 80 + (i * 40),
                          child: _ModernJadwalCard(
                            item: j,
                            tipe: j.selesai
                                ? _JadwalVisualType.selesai
                                : _JadwalVisualType.hariIni,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                    ],

                    // ── Kelompok: Besok ───────────────────────────
                    if (besok.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Besok',
                        count: besok.length,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                      ...List.generate(besok.length, (i) {
                        final j = besok[i];
                        return GerakEntrance(
                          delayMs: 100 + (i * 40),
                          child: _ModernJadwalCard(
                            item: j,
                            tipe: j.selesai
                                ? _JadwalVisualType.selesai
                                : _JadwalVisualType.mendatang,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                    ],

                    // ── Kelompok: Minggu depan ────────────────────
                    if (mingguDepan.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Minggu depan',
                        count: mingguDepan.length,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                      ...List.generate(mingguDepan.length, (i) {
                        final j = mingguDepan[i];
                        return GerakEntrance(
                          delayMs: 120 + (i * 40),
                          child: _ModernJadwalCard(
                            item: j,
                            tipe: j.selesai
                                ? _JadwalVisualType.selesai
                                : _JadwalVisualType.mendatang,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                    ],

                    // ── Kelompok: Riwayat Selesai ─────────────────
                    if (riwayatSelesai.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Selesai',
                        count: riwayatSelesai.length,
                        color: const Color(0xFF16A34A),
                        bgColor: const Color(0xFFDCFCE7),
                      ),
                      ...riwayatSelesai.map(
                        (j) => _ModernJadwalCard(
                          item: j,
                          tipe: _JadwalVisualType.selesai,
                          onToggle: () => _toggleSelesai(j),
                          onLongPress: () => _onLongPress(j),
                        ),
                      ),
                    ],

                    // ── Empty State ───────────────────────────────
                    if (hasNoItems)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                size: 32,
                                color: Color(0xFF0077E6),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Belum ada jadwal latihan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Buat jadwal latihan rutinmu sekarang agar progres kebugaranmu tetap konsisten setiap minggu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── 3. TOMBOL TAMBAH LATIHAN MODERN ────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _bukaFormTambah,
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                  label: const Text(
                    'Tambah Latihan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor:
                        const Color(0xFF0066CC).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNavBar(currentIndex: 1) : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// KOMPONEN KARTU RINGKASAN
// ═══════════════════════════════════════════════════════════════════

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color iconBgColor;
  final Color cardTintColor;

  const _SummaryStatCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.iconBgColor,
    required this.cardTintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardTintColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: count.toDouble()),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, val, _) => Text(
              '${val.round()}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HEADER KELOMPOK JADWAL
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color bgColor;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// KARTU JADWAL LATIHAN MODERN
// ═══════════════════════════════════════════════════════════════════

enum _JadwalVisualType { terlambat, hariIni, mendatang, selesai }

class _ModernJadwalCard extends StatelessWidget {
  final JadwalItem item;
  final _JadwalVisualType tipe;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const _ModernJadwalCard({
    required this.item,
    required this.tipe,
    required this.onToggle,
    required this.onLongPress,
  });

  String _formatHariTanggal(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;

    final tanggalPendek = DateFormat('d MMM', 'id_ID').format(dt);
    if (diff == 0) return 'Hari ini • $tanggalPendek';
    if (diff == 1) return 'Besok • $tanggalPendek';
    if (diff == -1) return 'Kemarin • $tanggalPendek';
    return '${DateFormat('EEEE', 'id_ID').format(dt)} •$tanggalPendek';
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor;
    final Color badgeBg;
    final Color cardBg;
    final Color borderColor;

    switch (tipe) {
      case _JadwalVisualType.terlambat:
        accentColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEE2E2);
        cardBg = const Color(0xFFFFFAFA);
        borderColor = const Color(0xFFFECACA);
        break;
      case _JadwalVisualType.hariIni:
        accentColor = const Color(0xFF0077E6);
        badgeBg = const Color(0xFFDBEAFE);
        cardBg = Colors.white;
        borderColor = const Color(0xFFBFDBFE);
        break;
      case _JadwalVisualType.mendatang:
        accentColor = const Color(0xFF0284C7);
        badgeBg = const Color(0xFFE0F2FE);
        cardBg = Colors.white;
        borderColor = const Color(0xFFE2E8F0);
        break;
      case _JadwalVisualType.selesai:
        accentColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFDCFCE7);
        cardBg = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFBBF7D0);
        break;
    }

    final targetInfo = item.infoTargetLatihan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onToggle,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Checkbox Interaktif ──────────────────────────
                AnimatedScale(
                  scale: item.selesai ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.selesai
                          ? const Color(0xFF16A34A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.selesai
                            ? const Color(0xFF16A34A)
                            : accentColor.withValues(alpha: 0.7),
                        width: 1.8,
                      ),
                    ),
                    child: item.selesai
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 13),

                // ── Informasi Latihan ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.judul,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                decoration: item.selesai
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: const Color(0xFF94A3B8),
                                color: item.selesai
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (targetInfo != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                targetInfo,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatHariTanggal(item.tanggal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item.selesai
                                    ? const Color(0xFF94A3B8)
                                    : accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.jamFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (item.ulangi &&
                              item.frekuensi != FrekuensiUlang.tidakUlang) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.repeat_rounded,
                              size: 13,
                              color: Color(0xFF0284C7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Badge Status ─────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.labelBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}