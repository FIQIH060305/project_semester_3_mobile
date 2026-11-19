import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gerak_animations.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../profil/profil_screen.dart';
import '../main_navigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool showBottomNav;
  const DashboardScreen({super.key, this.showBottomNav = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _namaPengguna = AuthService.instance.currentUser?.name ?? 'Sobat GERAK';
  int _langkahHariIni = 0;
  double _kaloriHariIni = 0;
  double _beratSekarang = AuthService.instance.currentUser?.beratBadan ?? 70.0;
  double _beratTarget = 65.0;
  double _sudahTurun = 0;
  int _totalSesiBulanIni = 0;

  late List<_LatihanData> latihanHariIni;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
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
    _loadDashboardFromServer();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        _namaPengguna = user.name;
        if (user.beratBadan != null) {
          _beratSekarang = user.beratBadan!;
        }
      }
    });
  }

  Future<void> _loadDashboardFromServer() async {
    final data = await AuthService.instance.fetchDashboardData();
    if (!mounted || data == null) return;

    setState(() {
      final user = data['user'] as Map<String, dynamic>?;
      final target = data['target'] as Map<String, dynamic>?;
      final hariIni = data['hari_ini'] as Map<String, dynamic>?;

      if (user != null) {
        _namaPengguna = user['nama_lengkap']?.toString() ?? _namaPengguna;
        _beratSekarang =
            double.tryParse(user['berat_sekarang']?.toString() ?? '') ??
                _beratSekarang;
      }
      if (target != null) {
        _beratTarget =
            double.tryParse(target['berat_target']?.toString() ?? '') ??
                _beratTarget;
        _sudahTurun =
            double.tryParse(target['sudah_turun']?.toString() ?? '') ?? 0;
      }
      if (hariIni != null) {
        _langkahHariIni =
            int.tryParse(hariIni['langkah']?.toString() ?? '') ?? 0;
        _kaloriHariIni =
            double.tryParse(hariIni['kalori']?.toString() ?? '') ?? 0;
      }
      _totalSesiBulanIni =
          int.tryParse(data['total_sesi_bulan_ini']?.toString() ?? '') ?? 0;
    });
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
        child: RefreshIndicator(
          color: const Color(0xFF1D5FC9),
          onRefresh: _loadDashboardFromServer,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GerakEntrance(delayMs: 0, child: _buildHeader()),
                const SizedBox(height: 16),
                GerakEntrance(delayMs: 80, child: _buildFokusPagiCard()),
                const SizedBox(height: 18),
                GerakEntrance(delayMs: 160, child: _buildLatihanCard()),
                const SizedBox(height: 16),
                GerakEntrance(
                  delayMs: 240,
                  child: Row(
                    children: [
                      Expanded(child: _buildLangkahCard()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildKaloriCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GerakEntrance(delayMs: 320, child: _buildBeratBadanCard()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _buildHeader() {
    final photoPath = AuthService.instance.currentUser?.photoPath;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hai, $_namaPengguna',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
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
        ),
        Row(
          children: [
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
                    '$_totalSesiBulanIni Sesi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final nav = MainNavigationController.of(context);
                if (nav != null) {
                  nav.switchTab(4);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilScreen()),
                  );
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2F80ED), width: 2),
                ),
                child: ClipOval(
                  child: _buildHeaderAvatar(photoPath),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAvatar(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith('http')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackHeaderAvatar(),
        );
      }
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackHeaderAvatar(),
        );
      }
    }
    return _buildFallbackHeaderAvatar();
  }

  Widget _buildFallbackHeaderAvatar() {
    return Image.asset(
      'assets/images/profile_user.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFDBEAFE),
        child: const Icon(
          Icons.person_rounded,
          color: Color(0xFF2F80ED),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFokusPagiCard() {
    return GestureDetector(
      onTap: () {
        final nav = MainNavigationController.of(context);
        if (nav != null) nav.switchTab(2); // Langsung arahkan ke tab Tracking
      },
      child: Container(
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
                    GerakPulseBeacon(
                      pulseColor: Colors.white,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FOKUS HARI INI • KETUK MULAI LARI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
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
            Positioned(
              right: 0,
              top: 2,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                  );
                },
                child: Icon(
                  Icons.notifications_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          ...List.generate(latihanHariIni.length, (index) {
            final item = latihanHariIni[index];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < latihanHariIni.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () => _toggleSelesai(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: item.selesai
                        ? const Color(0xFFD6EEFF)
                        : const Color(0xFFF1F7FF),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.judul,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                decoration: item.selesai
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: const Color(0xFF1F2937),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: item.selesai
                              ? const Color(0xFF8DC8FF)
                              : const Color(0xFFDBEAFE),
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

  Widget _buildLangkahCard() {
    final ratio = (_langkahHariIni / 10000).clamp(0.0, 1.0);
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
          GerakAnimatedMetric(
            targetValue: _langkahHariIni.toDouble(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          _buildPillProgressBar(ratio: ratio),
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

  Widget _buildKaloriCard() {
    final ratio = (_kaloriHariIni / 600).clamp(0.0, 1.0);
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
          const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF9800),
                size: 22,
              ),
              SizedBox(width: 4),
              Text(
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
          GerakAnimatedMetric(
            targetValue: _kaloriHariIni,
            suffix: ' kcal',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          _buildPillProgressBar(ratio: ratio),
          const SizedBox(height: 6),
          const Text(
            'Target 600 kcal',
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedRatio, _) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedRatio,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E60D0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBeratBadanCard() {
    final statusTurun = _sudahTurun >= 0
        ? '-${_sudahTurun.toStringAsFixed(1)} kg progres'
        : '+${_sudahTurun.abs().toStringAsFixed(1)} kg dari awal';

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
            children: [
              const Text(
                'Berat badan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                statusTurun,
                style: const TextStyle(
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
            children: [
              Text(
                '${_beratSekarang.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Target ${_beratTarget.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(painter: _TrendLinePainter()),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Awal program',
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
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.95),
      Offset(size.width * 0.85, size.height * 0.95),
      lacePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF009CBF)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.12, size.height * 0.3);
    path.lineTo(size.width * 0.88, size.height * 0.85);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}