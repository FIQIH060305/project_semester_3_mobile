import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// Grafik garis sederhana untuk tren berat badan, tanpa dependency tambahan
class MiniLineChart extends StatelessWidget {
  final List<double> nilai;
  const MiniLineChart({super.key, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(nilai)),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> nilai;
  _LinePainter(this.nilai);

  @override
  void paint(Canvas canvas, Size size) {
    if (nilai.length < 2) return;

    final paint = Paint()
      ..color = AppColors.brand
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final maxV = nilai.reduce((a, b) => a > b ? a : b);
    final minV = nilai.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < nilai.length; i++) {
      final x = size.width * i / (nilai.length - 1);
      final y = size.height - ((nilai[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}