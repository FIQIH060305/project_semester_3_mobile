import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'pelacakan_aktif_screen.dart';

class MulaiOlahragaScreen extends StatefulWidget {
  final String jenisOlahraga; // 'Berlari' atau 'Berjalan'
  final String targetSplit;
  final String jarakTarget;
  final String estKalori;
  final String estDurasi;

  const MulaiOlahragaScreen({
    super.key,
    this.jenisOlahraga = 'Berlari',
    this.targetSplit = "5’35” / km",
    this.jarakTarget = '5.0 KM',
    this.estKalori = '321 cal',
    this.estDurasi = '30 mnt',
  });

  @override
  State<MulaiOlahragaScreen> createState() => _MulaiOlahragaScreenState();
}

class _MulaiOlahragaScreenState extends State<MulaiOlahragaScreen> {
  int _countdown = 10;
  Timer? _timer;
  String _gpsAccuracyText = 'Memeriksa...';

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
    _startCountdown();
  }

  Future<void> _checkGpsStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 4)),
        );
        if (mounted) {
          setState(() {
            _gpsAccuracyText = 'Akurasi ${pos.accuracy.toStringAsFixed(0)}m';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _gpsAccuracyText = 'GPS Siap';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _gpsAccuracyText = 'GPS Siap';
        });
      }
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _mulaiTracking();
      }
    });
  }

  void _mulaiTracking() {
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PelacakanAktifScreen(
          jenisOlahraga: widget.jenisOlahraga,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0077E6),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              'GERAK SPORT',
              style: TextStyle(
                color: Color(0xFF0077E6),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Mulai Olahraga',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 1.4,
                  ),
                ),
                child: const Text(
                  'GPS siap',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // 1. Top Card: Target Olahraga & Estimasi
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Blue Highlight Bar
                    Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF60A5FA),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  widget.jenisOlahraga == 'Berjalan'
                                      ? Icons.directions_walk_rounded
                                      : Icons.directions_run_rounded,
                                  color: const Color(0xFF0077E6),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.jenisOlahraga,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Outdoor',
                                            style: TextStyle(
                                              color: Color(0xFF1D4ED8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Target  Split: ${widget.targetSplit}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Ganti mode',
                                  style: TextStyle(
                                    color: Color(0xFF0077E6),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 3 Stats in row
                          Row(
                            children: [
                              _buildMiniStatBox('JARAK TARGET', widget.jarakTarget),
                              const SizedBox(width: 8),
                              _buildMiniStatBox('EST. KALORI', widget.estKalori),
                              const SizedBox(width: 8),
                              _buildMiniStatBox('EST. DURASI', widget.estDurasi),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 2. Circular Gauge Countdown Widget
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom circular progress painter
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _CountdownCirclePainter(
                        progress: _countdown / 10.0,
                      ),
                    ),
                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Siap Mulai',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0077E6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_countdown',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Detik persiapan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Motivational Quote
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '“Kenakan sepatumu dan mulai langkah pertamamu sekarang juga!”',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. PEMERIKSA SISTEM Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PEMERIKSA SISTEM',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          width: 54,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Item 1: GPS Sinyal Kuat & Akurat
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '1',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'GPS Sinyal Kuat & Akurat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          _gpsAccuracyText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Item 2: Pelacakan Rute & Evaluasi
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '2',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Pelacakan Rute & Evaluasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const Text(
                          'Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 5. Bottom Button: MULAI SEKARANG
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _mulaiTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077E6),
                    elevation: 4,
                    shadowColor: const Color(0xFF0077E6).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.play_arrow_outlined, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'MULAI SEKARANG',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
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
      ),
    );
  }

  Widget _buildMiniStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownCirclePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _CountdownCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Outer thin light blue ring
    final outerRing = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius + 8, outerRing);

    // Inner background circle
    final innerBg = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, innerBg);

    // Active progress arc
    final progressArc = Paint()
      ..color = const Color(0xFF0077E6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressArc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

