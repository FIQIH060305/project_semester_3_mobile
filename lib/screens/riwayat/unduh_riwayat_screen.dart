import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/riwayat_item.dart';

class UnduhRiwayatScreen extends StatefulWidget {
  final RiwayatItem item;
  const UnduhRiwayatScreen({super.key, required this.item});

  @override
  State<UnduhRiwayatScreen> createState() => _UnduhRiwayatScreenState();
}

class _UnduhRiwayatScreenState extends State<UnduhRiwayatScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
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

  Future<void> _renderKartuRiwayat() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (!mounted) return;
      if (byteData != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0066CC),
            content: Text(
              'Kartu aktivitas berhasil dibuat dan siap dibagikan!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tanggalText =
        '${item.tanggal.day} ${_namaBulan(item.tanggal.month)} ${item.tanggal.year} • '
        '${item.tanggal.hour.toString().padLeft(2, '0')}:${item.tanggal.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _cardBoundaryKey,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
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
                            color:
                                const Color(0xFF0077E6).withValues(alpha: 0.35),
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
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
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
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
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
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.jarakKm.toStringAsFixed(2)} KM',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),

                          // Grid 3 Metrik Pendukung
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _cardStatItem('Durasi', item.durasiHms),
                                _cardStatItem('Kalori', '${item.kalori} kcal'),
                                _cardStatItem(
                                  'Langkah',
                                  item.sensorLangkahTersedia
                                      ? '${item.langkah}'
                                      : '-',
                                ),
                              ],
                            ),
                          ),

                          // Branding Footer GERAK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Color(0xFF38BDF8),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'GERAK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _renderKartuRiwayat,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    _isExporting ? 'Memproses...' : 'Simpan Kartu Aktivitas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _cardStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}