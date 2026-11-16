import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';
import '../../services/jadwal_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/jadwal_checklist_tile.dart';
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
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Toggle checklist — akan otomatis buat jadwal recurring jika aktif
  void _toggleSelesai(JadwalItem item) {
    _service.toggleSelesai(item);
  }

  /// Buka form tambah latihan baru
  Future<void> _bukaFormTambah() async {
    final hasil = await Navigator.of(context).push<JadwalItem>(
      MaterialPageRoute(builder: (_) => const TambahTugasScreen()),
    );
    if (hasil != null) {
      _service.tambahJadwal(hasil);
    }
  }

  /// Buka form edit jadwal
  Future<void> _bukaFormEdit(JadwalItem item) async {
    final hasil = await Navigator.of(context).push<JadwalItem>(
      MaterialPageRoute(builder: (_) => TambahTugasScreen(editItem: item)),
    );
    if (hasil != null) {
      _service.gantiJadwal(item.id, hasil);
    }
  }

  /// Dialog konfirmasi hapus jadwal
  Future<void> _konfirmasiHapus(JadwalItem item) async {
    final hapus = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.statRose, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Hapus Jadwal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
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
                  color: AppColors.textDark,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Jadwal '),
                  TextSpan(
                    text: '"${item.judul}"',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' akan dihapus.'),
                ],
              ),
            ),
            if (item.ulangi && item.frekuensi != FrekuensiUlang.tidakUlang)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statRoseBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.statRose, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pengulangan jadwal ini juga akan dihentikan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.statRose,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statRose,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Hapus',
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
      _service.hapusJadwal(item.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Jadwal "${item.judul}" berhasil dihapus.'),
              ),
            ],
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Long-press handler — tampilkan bottom sheet opsi (Edit / Hapus)
  void _onLongPress(JadwalItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Judul jadwal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    item.judul,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),

                // Info recurring
                if (item.ulangi && item.frekuensi != FrekuensiUlang.tidakUlang)
                  Text(
                    item.frekuensi == FrekuensiUlang.sekaliSehari
                        ? '🔁 Berulang setiap hari'
                        : '🔁 Berulang setiap minggu',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.brand.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 8),
                const Divider(),

                // Opsi Edit
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.brand),
                  title: const Text(
                    'Edit Jadwal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _bukaFormEdit(item);
                  },
                ),

                // Opsi Hapus
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline_rounded, color: AppColors.statRose),
                  title: const Text(
                    'Hapus Jadwal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.statRose,
                    ),
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
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final terlambat = _service.terlambat;
    final hariIni = _service.hariIni;
    final besok = _service.besok;
    final mingguDepan = _service.mingguDepan;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.brand, size: 32),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Buat jadwalmu sendiri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Statistik Cards ────────────────────────
                  Row(
                    children: [
                      // Card: Perlu dikejar (latihan terlewat)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.statRoseBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.statRose.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Perlu dikejar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statRose,
                                    ),
                                  ),
                                  const Icon(Icons.warning_amber_rounded,
                                      color: AppColors.statRose, size: 18),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_service.jumlahTerlambat}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Text(
                                'latihan terlewat',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Card: Tersisa minggu ini
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.badgeBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brand.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tersisa minggu ini',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  const Icon(Icons.event_note_rounded,
                                      color: AppColors.brand, size: 18),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_service.jumlahTersisaMingguIni}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Text(
                                'Latihan tersisa',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Daftar Jadwal ──────────────────────────

                  // Terlambat
                  if (terlambat.isNotEmpty) ...[
                    const _JudulSeksi(teks: 'Terlambat', warna: AppColors.statRose),
                    ...terlambat.map((j) => JadwalChecklistTile(
                          item: j,
                          terlambat: true,
                          onToggle: () => _toggleSelesai(j),
                          onLongPress: () => _onLongPress(j),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Hari ini
                  if (hariIni.isNotEmpty) ...[
                    const _JudulSeksi(teks: 'Hari ini', warna: AppColors.brand),
                    ...hariIni.map((j) => JadwalChecklistTile(
                          item: j,
                          onToggle: () => _toggleSelesai(j),
                          onLongPress: () => _onLongPress(j),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Besok
                  if (besok.isNotEmpty) ...[
                    const _JudulSeksi(teks: 'Besok', warna: AppColors.brand),
                    ...besok.map((j) => JadwalChecklistTile(
                          item: j,
                          onToggle: () => _toggleSelesai(j),
                          onLongPress: () => _onLongPress(j),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Minggu depan
                  if (mingguDepan.isNotEmpty) ...[
                    const _JudulSeksi(
                        teks: 'Minggu depan', warna: AppColors.brand),
                    ...mingguDepan.map((j) => JadwalChecklistTile(
                          item: j,
                          onToggle: () => _toggleSelesai(j),
                          onLongPress: () => _onLongPress(j),
                        )),
                  ],

                  // Pesan jika tidak ada jadwal
                  if (terlambat.isEmpty &&
                      hariIni.isEmpty &&
                      besok.isEmpty &&
                      mingguDepan.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 48,
                                color: AppColors.brand.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada jadwal latihan.\nTekan tombol di bawah untuk menambah.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Tombol Tambah Latihan ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _bukaFormTambah,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Tambah latihan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? const AppBottomNavBar(currentIndex: 1) : null,
    );
  }
}

// ─── Widget Judul Seksi ────────────────────────────────────────

class _JudulSeksi extends StatelessWidget {
  final String teks;
  final Color warna;
  const _JudulSeksi({required this.teks, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        teks,
        style: TextStyle(
          color: warna,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
