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

  Route<JadwalItem> _createSmoothRoute(Widget page) {
    return PageRouteBuilder<JadwalItem>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
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
              begin: const Offset(0, 0.04),
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

  Future<void> _respondJadwalPelatih(JadwalItem item, String aksi) async {
    String? catatan;
    if (aksi == 'rejected') {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tolak Jadwal dari Pelatih',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
          content: TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan penolakan untuk Pelatih...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tolak Jadwal'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      catatan = ctrl.text;
    }

    final res = await _service.respondRekomendasiPelatih(
      item: item,
      aksi: aksi,
      catatan: catatan,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor:
            res.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: const Text(
          'Hapus Jadwal',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text('Apakah kamu yakin ingin menghapus jadwal "${item.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (hapus == true) {
      await _service.hapusJadwal(item.id);
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
                      fontSize: 17, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_rounded,
                      color: Color(0xFF0077E6)),
                  title: const Text('Edit Jadwal',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _bukaFormEdit(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626)),
                  title: const Text('Hapus Jadwal',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626))),
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

  @override
  Widget build(BuildContext context) {
    final menunggu = _service.menungguPersetujuan;
    final terlambat = _service.terlambat;
    final hariIni = _service.hariIni;
    final besok = _service.besok;
    final mingguDepan = _service.mingguDepan;
    final riwayatSelesai = _service.riwayatSelesai;

    final hasNoItems = menunggu.isEmpty &&
        terlambat.isEmpty &&
        hariIni.isEmpty &&
        besok.isEmpty &&
        mingguDepan.isEmpty &&
        riwayatSelesai.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
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
                          'Jadwal Latihan Saya',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Kelola jadwal mandiri dan rekomendasi dari Pelatih',
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

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0077E6),
                onRefresh: _service.syncFromServer,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  children: [
                    // Kartu Ringkasan
                    GerakEntrance(
                      delayMs: 30,
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

                    const SizedBox(height: 16),

                    // ── Kelompok Khusus: Rekomendasi Jadwal dari Pelatih ─
                    if (menunggu.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Rekomendasi Pelatih (Perlu Konfirmasi)',
                        count: menunggu.length,
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                      ...menunggu.map((j) => _RekomendasiPelatihCard(
                            item: j,
                            onAccept: () =>
                                _respondJadwalPelatih(j, 'accepted'),
                            onReject: () =>
                                _respondJadwalPelatih(j, 'rejected'),
                          )),
                      const SizedBox(height: 14),
                    ],

                    if (terlambat.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Terlambat',
                        count: terlambat.length,
                        color: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEE2E2),
                      ),
                      ...terlambat.map((j) => _ModernJadwalCard(
                            item: j,
                            tipe: _JadwalVisualType.terlambat,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          )),
                      const SizedBox(height: 14),
                    ],

                    if (hariIni.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Hari ini',
                        count: hariIni.length,
                        color: const Color(0xFF0077E6),
                        bgColor: const Color(0xFFDBEAFE),
                      ),
                      ...hariIni.map((j) => _ModernJadwalCard(
                            item: j,
                            tipe: j.selesai
                                ? _JadwalVisualType.selesai
                                : _JadwalVisualType.hariIni,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          )),
                      const SizedBox(height: 14),
                    ],

                    if (besok.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Besok',
                        count: besok.length,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                      ...besok.map((j) => _ModernJadwalCard(
                            item: j,
                            tipe: j.selesai
                                ? _JadwalVisualType.selesai
                                : _JadwalVisualType.mendatang,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          )),
                      const SizedBox(height: 14),
                    ],

                    if (mingguDepan.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Minggu depan',
                        count: mingguDepan.length,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                      ...mingguDepan.map((j) => _ModernJadwalCard(
                            item: j,
                            tipe: j.selesai
                                ? _JadwalVisualType.selesai
                                : _JadwalVisualType.mendatang,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          )),
                      const SizedBox(height: 14),
                    ],

                    if (riwayatSelesai.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Selesai',
                        count: riwayatSelesai.length,
                        color: const Color(0xFF16A34A),
                        bgColor: const Color(0xFFDCFCE7),
                      ),
                      ...riwayatSelesai.map((j) => _ModernJadwalCard(
                            item: j,
                            tipe: _JadwalVisualType.selesai,
                            onToggle: () => _toggleSelesai(j),
                            onLongPress: () => _onLongPress(j),
                          )),
                    ],

                    if (hasNoItems)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 42, color: Color(0xFF0077E6)),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada jadwal latihan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Buat jadwal latihan mandiri atau terima jadwal dari Pelatih pendampingmu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              color: const Color(0xFFF7FAFF),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _bukaFormTambah,
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                  label: const Text(
                    'Tambah Latihan Mandiri',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
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

class _RekomendasiPelatihCard extends StatelessWidget {
  final JadwalItem item;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RekomendasiPelatihCard({
    required this.item,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final tglLabel = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(item.tanggal);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Dari ${item.namaPelatih ?? 'Pelatih'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0066CC),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${item.durasiMenit ?? 30} mnt • ${item.intensitas ?? 'Sedang'}',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.judul,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 3),
          Text(
            '$tglLabel • Pukul ${item.jamFormatted}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (item.catatanPelatih != null &&
              item.catatanPelatih!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${item.catatanPelatih}"',
              style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF475569)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Terima Jadwal'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.1,
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
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
    return '${DateFormat('EEEE', 'id_ID').format(dt)} • $tanggalPendek';
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onToggle,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.selesai ? const Color(0xFF16A34A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.selesai
                        ? const Color(0xFF16A34A)
                        : accentColor.withValues(alpha: 0.7),
                    width: 1.8,
                  ),
                ),
                child: item.selesai
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 13),
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
                              color: item.selesai
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (item.dariPelatih) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Pelatih',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatHariTanggal(item.tanggal)} • Pukul ${item.jamFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.selesai
                            ? const Color(0xFF94A3B8)
                            : accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
    );
  }
}