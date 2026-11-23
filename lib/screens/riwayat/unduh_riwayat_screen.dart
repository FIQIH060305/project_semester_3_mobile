import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../../models/riwayat_item.dart';

enum _CardBackgroundStyle {
  blueGradient,
  transparentOverlay,
}

class UnduhRiwayatScreen extends StatefulWidget {
  final RiwayatItem item;
  const UnduhRiwayatScreen({super.key, required this.item});

  @override
  State<UnduhRiwayatScreen> createState() => _UnduhRiwayatScreenState();
}

class _UnduhRiwayatScreenState extends State<UnduhRiwayatScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  _CardBackgroundStyle _selectedStyle = _CardBackgroundStyle.blueGradient;
  bool _isExporting = false;

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

  Future<void> _unduhKartuRiwayat() async {
    if (_isExporting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);

    try {
      // Pastikan frame selesai dirender sebelum ditangkap menjadi PNG
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;

      final boundary = _cardBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal mengonversi gambar.');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final modeLabel = _selectedStyle == _CardBackgroundStyle.blueGradient
          ? 'card'
          : 'transparent';
      final fileName =
          'GERAK_${widget.item.jenis}_${modeLabel}_${DateTime.now().millisecondsSinceEpoch}';

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putImageBytes(
        pngBytes,
        name: fileName,
        album: 'GERAK',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0077E6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedStyle == _CardBackgroundStyle.transparentOverlay
                      ? 'Stiker transparan PNG tersimpan di Galeri (Album GERAK)!'
                      : 'Kartu aktivitas tersimpan di Galeri (Album GERAK)!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD84343),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            'Gagal menyimpan gambar ke Galeri: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isTransparent =
        _selectedStyle == _CardBackgroundStyle.transparentOverlay;

    final tanggalText =
        '${item.tanggal.day} ${_namaBulan(item.tanggal.month)} ${item.tanggal.year} • '
        '${item.tanggal.hour.toString().padLeft(2, '0')}:${item.tanggal.minute.toString().padLeft(2, '0')}';

    // Bayangan teks agar tetap kontras saat mode transparan ditempel di foto terang
    final List<Shadow> transparentShadows = isTransparent
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.58),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ]
        : const [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: const Text(
          'Kartu Aktivitas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              // ── 1. PILIHAN MODE BACKGROUND ──────────────────────────
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _BackgroundOptionTab(
                        label: 'Biru Gradien',
                        icon: Icons.gradient_rounded,
                        selected: !isTransparent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedStyle =
                              _CardBackgroundStyle.blueGradient);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _BackgroundOptionTab(
                        label: 'Tanpa Background',
                        icon: Icons.grid_on_rounded,
                        selected: isTransparent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedStyle =
                              _CardBackgroundStyle.transparentOverlay);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTransparent
                    ? 'Format PNG transparan — siap ditempel di atas foto pribadimu'
                    : 'Kartu siap bagikan dengan latar biru gradien GERAK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // ── 2. AREA PREVIEW & REPAINT BOUNDARY ──────────────────
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Penanda checkerboard khusus mode transparan (TIDAK ikut dirender ke PNG)
                        if (isTransparent)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: CustomPaint(
                              painter: _TransparencyCheckerPainter(),
                            ),
                          ),

                        // Konten yang akan diekspor ke PNG
                        RepaintBoundary(
                          key: _cardBoundaryKey,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 22),
                            decoration: isTransparent
                                ? const BoxDecoration(
                                    color: Colors.transparent,
                                  )
                                : BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0077E6),
                                        Color(0xFF0284C7),
                                        Color(0xFF0F2B5C),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0077E6)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Header Jenis Aktivitas & Tanggal
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isTransparent
                                            ? Colors.black
                                                .withValues(alpha: 0.25)
                                            : Colors.white
                                                .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(20),
                                        border: isTransparent
                                            ? Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.35),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            item.jenis == 'Berjalan'
                                                ? Icons.directions_walk_rounded
                                                : Icons.directions_run_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.jenis.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      tanggalText,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.90),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        shadows: transparentShadows,
                                      ),
                                    ),
                                  ],
                                ),

                                // Metrik Utama (Jarak)
                                Column(
                                  children: [
                                    Text(
                                      'JARAK TEMPUH',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.84),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                        shadows: transparentShadows,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${item.jarakKm.toStringAsFixed(2)} KM',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                          shadows: transparentShadows,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Grid 3 Metrik Pendukung
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: isTransparent
                                      ? BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                            bottom: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                        )
                                      : BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.13),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _cardStatItem(
                                        'Durasi',
                                        item.durasiHms,
                                        shadows: transparentShadows,
                                      ),
                                      _cardStatItem(
                                        'Kalori',
                                        '${item.kalori} kcal',
                                        shadows: transparentShadows,
                                      ),
                                      _cardStatItem(
                                        'Langkah',
                                        item.sensorLangkahTersedia
                                            ? '${item.langkah}'
                                            : '-',
                                        shadows: transparentShadows,
                                      ),
                                    ],
                                  ),
                                ),

                                // Branding Footer dengan Logo GERAK
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/logo_gerak.png',
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.bolt_rounded,
                                        color: Color(0xFF38BDF8),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'GERAK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 2.0,
                                        shadows: transparentShadows,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── 3. TOMBOL UNDUH KE GALERI ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _unduhKartuRiwayat,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    _isExporting
                        ? 'Menyimpan ke Galeri...'
                        : (isTransparent
                            ? 'Unduh PNG Transparan'
                            : 'Unduh Kartu Aktivitas'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077E6),
                    disabledBackgroundColor:
                        const Color(0xFF0077E6).withValues(alpha: 0.6),
                    elevation: 3,
                    shadowColor:
                        const Color(0xFF0077E6).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardStatItem(
    String label,
    String value, {
    List<Shadow> shadows = const [],
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: shadows,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            shadows: shadows,
          ),
        ),
      ],
    );
  }
}

class _BackgroundOptionTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundOptionTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0077E6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransparencyCheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double cellSize = 16.0;
    final paintDark = Paint()..color = const Color(0xFF1E293B);
    final paintLight = Paint()..color = const Color(0xFF283548);

    canvas.drawRect(Offset.zero & size, paintDark);

    for (double y = 0; y < size.height; y += cellSize) {
      final row = (y / cellSize).floor();
      for (double x = 0; x < size.width; x += cellSize) {
        final col = (x / cellSize).floor();
        if ((row + col).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, cellSize, cellSize),
            paintLight,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}