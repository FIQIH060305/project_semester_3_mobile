import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ============================================================
          // DEKORASI GELOMBANG BIRU ATAS — dua lapis untuk kedalaman
          // ============================================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(heightFactor: 0.58),
              child: Container(
                height: size.height * 0.32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B5A9E), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Lapis kedua — warna sedikit lebih muda, sedikit lebih pendek
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(heightFactor: 0.72),
              child: Container(
                height: size.height * 0.28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // ============================================================
          // KONTEN UTAMA
          // ============================================================
          SafeArea(
            child: Column(
              children: [
                // Ruang di bawah wave
                SizedBox(height: size.height * 0.28 + 16),

                // Logo GERAK
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_gerak.png',
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Sehat Hari ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const Text(
                        'lebih baik setiap hari.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Mulai
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Mulai',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
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
}

/// Wave clipper dengan kontrol heightFactor untuk dua lapis gelombang.
class _WaveClipper extends CustomClipper<Path> {
  final double heightFactor;
  const _WaveClipper({this.heightFactor = 0.65});

  @override
  Path getClip(Size size) {
    final path = Path();
    final h = size.height;
    final w = size.width;
    path.lineTo(0, h * heightFactor);
    path.cubicTo(
      w * 0.2, h * (heightFactor + 0.25),
      w * 0.6, h * (heightFactor - 0.15),
      w, h * heightFactor,
    );
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper old) =>
      old.heightFactor != heightFactor;
}