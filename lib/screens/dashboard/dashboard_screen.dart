import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final namaPengguna = 'Robit';
  final streakHari = 10;

  // Daftar latihan hari ini yang dapat ditoggle
  late List<_LatihanData> latihanHariIni;

  @override
  void initState() {
    super.initState();
    latihanHariIni = [
      _LatihanData(
        judul: 'Jalan 30 menit',
        waktu: 'Hari ini, 07.00',
        labelBadge: 'Tuntas',
        selesai: true,
      ),
      _LatihanData(
        judul: 'Berlari 30 menit',
        waktu: 'Hari ini, 10.00',
        labelBadge: 'Nanti',
        selesai: false,
      ),
      _LatihanData(
        judul: 'Push up 50 reps',
        waktu: 'Hari ini, 15.00',
        labelBadge: 'Besok',
        selesai: false,
      ),
    ];
  }

  void _toggleSelesai(int index) {
    setState(() {
      latihanHariIni[index].selesai = !latihanHariIni[index].selesai;
      if (latihanHariIni[index].selesai) {
        latihanHariIni[index].labelBadge = 'Tuntas';
      } else {
        latihanHariIni[index].labelBadge = index == 1 ? 'Nanti' : 'Besok';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. HEADER (Nama & Streak)
              // ==========================================
              _buildHeader(),
              const SizedBox(height: 16),

              // ==========================================
              // 2. KARTU "FOKUS PAGI"
              // ==========================================
              _buildFokusPagiCard(),
              const SizedBox(height: 18),

              // ==========================================
              // 3. CARD "LATIHAN HARI INI"
              // ==========================================
              _buildLatihanCard(),
              const SizedBox(height: 16),

              // ==========================================
              // 4. STAT CARD (LANGKAH & KALORI)
              // ==========================================
              Row(
                children: [
                  Expanded(
                    child: _buildLangkahCard(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildKaloriCard(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==========================================
              // 5. CARD "BERAT BADAN"
              // ==========================================
              _buildBeratBadanCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── 1. HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hai, $namaPengguna',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '👋',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Semangat jaga kesehatan!',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Badge Streak
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDF7D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                '$streakHari Hari',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. FOKUS PAGI CARD ───────────────────────────────────────────────
  Widget _buildFokusPagiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5697F8), Color(0xFF1D5FC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D5FC9).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FOKUS PAGI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Bersiap capai 5KM Pertamamu!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                ),
              ),
            ],
          ),

          // Icon Lonceng Notifikasi di pojok kanan
          Positioned(
            right: 0,
            top: 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 38,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 1),
                    child: Text(
                      '99+',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. LATIHAN HARI INI CARD ─────────────────────────────────────────
  Widget _buildLatihanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Latihan
          Row(
            children: [
              Transform.rotate(
                angle: -0.5,
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF00A3FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Latihan Hari ini',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List item
          ...List.generate(latihanHariIni.length, (index) {
            final item = latihanHariIni[index];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < latihanHariIni.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () => _toggleSelesai(index),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6EEFF),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      // Checklist Box
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: item.selesai
                              ? const Color(0xFF0084FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.selesai
                                ? const Color(0xFF0084FF)
                                : const Color(0xFF1F2937),
                            width: 1.6,
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
                      const SizedBox(width: 14),

                      // Judul & Jam
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.judul,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.waktu,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge Kapsul Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8DC8FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          item.labelBadge,
                          style: const TextStyle(
                            color: Color(0xFF0F4882),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 4. CARD LANGKAH ──────────────────────────────────────────────────
  Widget _buildLangkahCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD7FCD7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8BF08B), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomPaint(
                size: const Size(22, 16),
                painter: _SneakerIconPainter(),
              ),
              const SizedBox(width: 6),
              const Text(
                'Langkah',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '1000',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          _buildPillProgressBar(ratio: 0.1),

          const SizedBox(height: 6),
          const Text(
            'Target 10,000',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. CARD KALORI ───────────────────────────────────────────────────
  Widget _buildKaloriCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF9800),
                size: 22,
              ),
              const SizedBox(width: 4),
              const Text(
                'Kalori',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '1000',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          _buildPillProgressBar(ratio: 0.1),

          const SizedBox(height: 6),
          const Text(
            'Target 10,000',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillProgressBar({required double ratio}) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: ratio.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E60D0),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ── 5. CARD BERAT BADAN ──────────────────────────────────────────────
  Widget _buildBeratBadanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Berat badan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '-1,5 kg minggu ini',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '90,5 kg',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Target 75 kg',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Grafik Garis Tren Menurun
          SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendLinePainter(),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '1 minggu lalu',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Sekarang',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── DATA MODEL LATIHAN ──────────────────────────────────────────────────
class _LatihanData {
  String judul;
  String waktu;
  String labelBadge;
  bool selesai;

  _LatihanData({
    required this.judul,
    required this.waktu,
    required this.labelBadge,
    required this.selesai,
  });
}

// ── CUSTOM PAINTER UNTUK ICON SEPATU (SNEAKER OUTLINE) ──────────────────
class _SneakerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Gambar outline sneaker sederhana miring
    path.moveTo(size.width * 0.15, size.height * 0.25);
    path.lineTo(size.width * 0.35, size.height * 0.1);
    path.lineTo(size.width * 0.55, size.height * 0.45);
    path.lineTo(size.width * 0.9, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.85,
      size.width * 0.8,
      size.height * 0.85,
    );
    path.lineTo(size.width * 0.1, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.05,
      size.height * 0.55,
      size.width * 0.15,
      size.height * 0.25,
    );

    canvas.drawPath(path, paint);

    // Garis tali sepatu
    final lacePaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.35),
      Offset(size.width * 0.45, size.height * 0.42),
      lacePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.55, size.height * 0.58),
      lacePaint,
    );
    // Sol bawah
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.95),
      Offset(size.width * 0.85, size.height * 0.95),
      lacePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CUSTOM PAINTER UNTUK GARIS TREN MENURUN ─────────────────────────────
class _TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF009CBF)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Garis miring halus dari kiri atas ke kanan bawah
    path.moveTo(size.width * 0.12, size.height * 0.3);
    path.lineTo(size.width * 0.88, size.height * 0.85);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}