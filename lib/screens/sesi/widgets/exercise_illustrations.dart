import 'package:flutter/material.dart';

class WalkingIllustrationWidget extends StatelessWidget {
  final double width;
  final double height;

  const WalkingIllustrationWidget({
    super.key,
    this.width = 65,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _WalkingPainter(),
      ),
    );
  }
}

class _WalkingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 80.0;
    canvas.save();
    canvas.scale(scale, scale);

    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    final hairPaint = Paint()..color = const Color(0xFFFBBF24); // golden yellow
    final shirtPaint = Paint()..color = const Color(0xFF00B4D8); // vibrant cyan-blue
    final pantsPaint = Paint()..color = const Color(0xFF475569); // slate dark grey
    final shoePaint = Paint()..color = const Color(0xFF334155);

    // Head
    canvas.drawCircle(const Offset(38, 14), 7, skinPaint);
    // Hair
    final hairPath = Path()
      ..moveTo(31, 14)
      ..quadraticBezierTo(32, 6, 40, 7)
      ..quadraticBezierTo(46, 9, 45, 14)
      ..quadraticBezierTo(41, 11, 35, 12)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Torso (Shirt)
    final torsoPath = Path()
      ..moveTo(33, 21)
      ..lineTo(43, 21)
      ..lineTo(40, 42)
      ..lineTo(31, 41)
      ..close();
    canvas.drawPath(torsoPath, shirtPaint);

    // Left Arm (swinging back)
    final backArm = Path()
      ..moveTo(40, 22)
      ..lineTo(48, 30)
      ..lineTo(51, 36);
    canvas.drawPath(
      backArm,
      Paint()
        ..color = const Color(0xFF00B4D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Right Arm (swinging forward)
    final frontArm = Path()
      ..moveTo(34, 23)
      ..lineTo(26, 31)
      ..lineTo(23, 37);
    canvas.drawPath(
      frontArm,
      Paint()
        ..color = const Color(0xFF00B4D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Left Leg (back)
    final backLeg = Path()
      ..moveTo(38, 41)
      ..lineTo(46, 57)
      ..lineTo(52, 70);
    canvas.drawPath(
      backLeg,
      Paint()
        ..color = pantsPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    // Back shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(49, 68, 12, 6),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    // Right Leg (front stride)
    final frontLeg = Path()
      ..moveTo(33, 41)
      ..lineTo(26, 56)
      ..lineTo(18, 69);
    canvas.drawPath(
      frontLeg,
      Paint()
        ..color = pantsPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.2
        ..strokeCap = StrokeCap.round,
    );
    // Front shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 68, 13, 6),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RunningIllustrationWidget extends StatelessWidget {
  final double width;
  final double height;

  const RunningIllustrationWidget({
    super.key,
    this.width = 65,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _RunningPainter(),
      ),
    );
  }
}

class _RunningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 80.0;
    canvas.save();
    canvas.scale(scale, scale);

    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    final hairPaint = Paint()..color = const Color(0xFFFBBF24); // golden yellow
    final shirtPaint = Paint()..color = const Color(0xFF00D2D3); // bright electric cyan
    final pantsPaint = Paint()..color = const Color(0xFF475569);
    final shoePaint = Paint()..color = const Color(0xFF334155);

    // Head tilted forward in running pose
    canvas.drawCircle(const Offset(34, 15), 7, skinPaint);
    // Hair
    final hairPath = Path()
      ..moveTo(27, 15)
      ..quadraticBezierTo(28, 7, 36, 8)
      ..quadraticBezierTo(43, 10, 42, 16)
      ..quadraticBezierTo(38, 12, 31, 13)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Torso (leaning forward)
    final torsoPath = Path()
      ..moveTo(30, 22)
      ..lineTo(40, 22)
      ..lineTo(35, 42)
      ..lineTo(25, 39)
      ..close();
    canvas.drawPath(torsoPath, shirtPaint);

    // Back arm (bent back)
    final backArm = Path()
      ..moveTo(37, 23)
      ..lineTo(46, 26)
      ..lineTo(42, 35);
    canvas.drawPath(
      backArm,
      Paint()
        ..color = shirtPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Front arm (thrust forward)
    final frontArm = Path()
      ..moveTo(28, 24)
      ..lineTo(16, 26)
      ..lineTo(21, 17);
    canvas.drawPath(
      frontArm,
      Paint()
        ..color = shirtPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Back leg (extended backward high)
    final backLeg = Path()
      ..moveTo(33, 41)
      ..lineTo(43, 48)
      ..lineTo(54, 46);
    canvas.drawPath(
      backLeg,
      Paint()
        ..color = pantsPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Back shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 43, 10, 6),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    // Front leg (bent high knee forward)
    final frontLeg = Path()
      ..moveTo(28, 40)
      ..lineTo(20, 52)
      ..lineTo(32, 68);
    canvas.drawPath(
      frontLeg,
      Paint()
        ..color = pantsPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Front shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 66, 12, 6),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

