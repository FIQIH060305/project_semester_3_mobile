import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnim;
  late final Animation<double> _logoFadeAnim;
  late final Animation<double> _logoScaleAnim;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _logoFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _logoScaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });

    _controller.forward();
  }

  void _navigateNext() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final auth = AuthService.instance;
    if (!auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    if (auth.isCoach) {
      final target =
          auth.isCoachApproved ? '/coach-dashboard' : '/coach-verifikasi';
      Navigator.of(context).pushReplacementNamed(target);
      return;
    }

    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final barWidth = (screenSize.width * 0.72).clamp(220.0, 310.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 1. GELOMBANG BIRU BERLAPIS DI BAGIAN ATAS ──────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.24,
            child: CustomPaint(
              painter: _TopWavePainter(),
            ),
          ),

          // ── 2. LOGO GERAK DI TENGAH LAYAR ──────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _logoFadeAnim,
              child: ScaleTransition(
                scale: _logoScaleAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: _buildGerakLogo(),
                ),
              ),
            ),
          ),

          // ── 3. IKON PELARI & PROGRESS BAR PERSENTASE DI BAWAH ──────────
          Positioned(
            left: 0,
            right: 0,
            bottom: screenSize.height * 0.14,
            child: Center(
              child: SizedBox(
                width: barWidth,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    final value = _progressAnim.value.clamp(0.0, 1.0);
                    final percent = (value * 100).round();
                    const runnerSize = 32.0;
                    final maxRunnerTravel =
                        (barWidth - 95.0).clamp(40.0, barWidth);
                    final runnerLeft =
                        (value * maxRunnerTravel).clamp(4.0, maxRunnerTravel);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 36,
                          width: barWidth,
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              Positioned(
                                left: runnerLeft,
                                bottom: 2,
                                child: const Icon(
                                  Icons.directions_run_rounded,
                                  color: Color(0xFF005CA8),
                                  size: runnerSize,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Text(
                                  '$percent %',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 18,
                          width: barWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0277BD),
                              width: 1.3,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value <= 0.02 ? 0.02 : value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0077C2),
                                      Color(0xFF0284C7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGerakLogo() {
    return Image.asset(
      'assets/images/logo_gerak.png',
      width: 235,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/images/logo.png',
        width: 235,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_run_rounded,
              size: 84,
              color: Color(0xFF0077E6),
            ),
            SizedBox(height: 8),
            Text(
              'GERAK',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0066CC),
                letterSpacing: 2,
              ),
            ),
            Text(
              'ACTIVE & HEALTHY LIFE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF38BDF8),
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paleBluePaint = Paint()
      ..color = const Color(0xFFD2E4F6)
      ..style = PaintingStyle.fill;

    final palePath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.78)
      ..cubicTo(
        w * 0.86,
        h * 0.88,
        w * 0.64,
        h * 0.72,
        w * 0.42,
        h * 0.56,
      )
      ..cubicTo(
        w * 0.24,
        h * 0.44,
        w * 0.10,
        h * 0.48,
        0,
        h * 0.54,
      )
      ..close();
    canvas.drawPath(palePath, paleBluePaint);

    final leftShadowPaint = Paint()
      ..color = const Color(0xFFCBD8E8)
      ..style = PaintingStyle.fill;

    final leftShadowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.45, 0)
      ..lineTo(w * 0.45, h * 0.42)
      ..cubicTo(
        w * 0.26,
        h * 0.30,
        w * 0.12,
        h * 0.24,
        0,
        h * 0.26,
      )
      ..close();
    canvas.drawPath(leftShadowPath, leftShadowPaint);

    final midBluePaint = Paint()
      ..color = const Color(0xFF0265B8)
      ..style = PaintingStyle.fill;

    final midPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.62)
      ..cubicTo(
        w * 0.82,
        h * 0.86,
        w * 0.58,
        h * 0.76,
        w * 0.38,
        h * 0.52,
      )
      ..cubicTo(
        w * 0.22,
        h * 0.34,
        w * 0.08,
        h * 0.38,
        0,
        h * 0.44,
      )
      ..close();
    canvas.drawPath(midPath, midBluePaint);

    final darkNavyPaint = Paint()
      ..color = const Color(0xFF002D7C)
      ..style = PaintingStyle.fill;

    final darkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.30)
      ..cubicTo(
        w * 0.82,
        h * 0.54,
        w * 0.62,
        h * 0.64,
        w * 0.38,
        h * 0.48,
      )
      ..cubicTo(
        w * 0.20,
        h * 0.36,
        w * 0.08,
        h * 0.26,
        0,
        h * 0.26,
      )
      ..close();
    canvas.drawPath(darkPath, darkNavyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}