import 'package:flutter/material.dart';

class TrackingMapWidget extends StatelessWidget {
  final VoidCallback? onExpand;
  final VoidCallback? onCenterLocation;

  const TrackingMapWidget({
    super.key,
    this.onExpand,
    this.onCenterLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Background Canvas Map
          Positioned.fill(
            child: CustomPaint(
              painter: _RealisticTrackingMapPainter(),
            ),
          ),

          // Map Control Buttons (Top Left & Top Right)
          Positioned(
            top: 14,
            left: 14,
            child: GestureDetector(
              onTap: onExpand,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.open_in_full_rounded,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
          ),

          Positioned(
            top: 14,
            right: 14,
            child: GestureDetector(
              onTap: onCenterLocation,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF1E293B),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealisticTrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base land color (soft warm cream / light grey)
    final bgPaint = Paint()..color = const Color(0xFFE8ECE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Green nature/park zones
    final parkPaint = Paint()..color = const Color(0xFFD4E7D0);
    // Top-left park
    canvas.drawOval(Rect.fromLTWH(-20, -30, w * 0.45, h * 0.25), parkPaint);
    // Mid park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.22, w * 0.5, h * 0.2),
        const Radius.circular(40),
      ),
      parkPaint,
    );
    // Lower left park
    canvas.drawOval(Rect.fromLTWH(-30, h * 0.5, w * 0.55, h * 0.3), parkPaint);
    // Bottom park
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.72, w * 0.8, h * 0.35), parkPaint);

    // 3. Water body (river / lake Havel)
    final waterPaint = Paint()
      ..color = const Color(0xFFABC5DE)
      ..style = PaintingStyle.fill;

    final waterPath = Path()
      ..moveTo(w * 0.85, 0)
      ..quadraticBezierTo(w * 0.82, h * 0.15, w * 0.86, h * 0.3)
      ..quadraticBezierTo(w * 0.78, h * 0.45, w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.88, h * 0.8, w * 0.84, h)
      ..lineTo(w, h)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Lake on the left (Gross Glienicker See)
    final lakePath = Path()
      ..addOval(Rect.fromLTWH(w * 0.35, h * 0.32, w * 0.18, h * 0.15));
    canvas.drawPath(lakePath, waterPaint);

    // Lake Sacrow
    final lakeSacrow = Path()
      ..addOval(Rect.fromLTWH(w * 0.2, h * 0.46, w * 0.22, h * 0.08));
    canvas.drawPath(lakeSacrow, waterPaint);

    // 4. Street Grid & Highway Lines
    final localRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final mainRoad = Paint()
      ..color = const Color(0xFFFDE68A) // warm highway yellow
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    final roadBorder = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 5.8
      ..style = PaintingStyle.stroke;

    // Highway B5 across top
    final hwy5 = Path()
      ..moveTo(0, h * 0.12)
      ..cubicTo(w * 0.3, h * 0.14, w * 0.6, h * 0.08, w, h * 0.13);
    canvas.drawPath(hwy5, roadBorder);
    canvas.drawPath(hwy5, mainRoad);

    // Highway B2 going vertical-diagonal
    final hwy2 = Path()
      ..moveTo(w * 0.12, h * 0.35)
      ..lineTo(0, h * 0.42);
    canvas.drawPath(hwy2, roadBorder);
    canvas.drawPath(hwy2, mainRoad);

    // Grid roads
    final road1 = Path()
      ..moveTo(w * 0.32, 0)
      ..lineTo(w * 0.45, h * 0.35)
      ..quadraticBezierTo(w * 0.5, h * 0.45, w * 0.48, h * 0.65)
      ..lineTo(w * 0.52, h);
    canvas.drawPath(road1, localRoad);

    final road2 = Path()
      ..moveTo(0, h * 0.28)
      ..lineTo(w * 0.78, h * 0.22);
    canvas.drawPath(road2, localRoad);

    final road3 = Path()
      ..moveTo(w * 0.15, h * 0.55)
      ..lineTo(w * 0.75, h * 0.52);
    canvas.drawPath(road3, localRoad);

    final road4 = Path()
      ..moveTo(w * 0.3, h * 0.75)
      ..lineTo(w * 0.8, h * 0.72);
    canvas.drawPath(road4, localRoad);

    // 5. Place Labels (Staaken, Seeburg, Gatow, Kladow, Sacrow)
    _drawText(canvas, 'STAAKEN', Offset(w * 0.42, h * 0.09), fontSize: 8.5, color: const Color(0xFF64748B));
    _drawText(canvas, 'Seeburg', Offset(w * 0.38, h * 0.19), fontSize: 10, color: const Color(0xFF475569), isBold: true);
    _drawText(canvas, 'WILHELMSTADT', Offset(w * 0.68, h * 0.17), fontSize: 8.5, color: const Color(0xFF64748B));
    _drawText(canvas, 'GATOW', Offset(w * 0.65, h * 0.28), fontSize: 9, color: const Color(0xFF64748B));
    _drawText(canvas, 'KLADOW', Offset(w * 0.45, h * 0.38), fontSize: 9.5, color: const Color(0xFF475569), isBold: true);
    _drawText(canvas, 'SACROW', Offset(w * 0.22, h * 0.46), fontSize: 8.5, color: const Color(0xFF64748B));

    // 6. Running Route Polyline (Thick crimson-red path)
    final routeBorderPaint = Paint()
      ..color = const Color(0xFF7F1D1D).withValues(alpha: 0.4)
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePaint = Paint()
      ..color = const Color(0xFFB91C1C) // vibrant crimson red
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePath = Path()
      ..moveTo(w * 0.86, h * 0.12)
      ..lineTo(w * 0.82, h * 0.18)
      ..lineTo(w * 0.83, h * 0.26)
      ..quadraticBezierTo(w * 0.89, h * 0.34, w * 0.78, h * 0.42)
      ..lineTo(w * 0.8, h * 0.52)
      ..quadraticBezierTo(w * 0.76, h * 0.56, w * 0.52, h * 0.54)
      ..lineTo(w * 0.5, h * 0.42); // ends near GPS beacon

    canvas.drawPath(routePath, routeBorderPaint);
    canvas.drawPath(routePath, routePaint);

    // 7. Navigation GPS Beacon (Blue pulsing circle with direction arrow)
    final beaconCenter = Offset(w * 0.5, h * 0.34);

    // Pulse outer halo
    final pulsePaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35);
    canvas.drawCircle(beaconCenter, 24, pulsePaint);

    // Inner bright blue circle
    final innerBeacon = Paint()
      ..color = const Color(0xFF2563EB);
    canvas.drawCircle(beaconCenter, 16, innerBeacon);

    // White border ring
    final beaconBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(beaconCenter, 16, beaconBorder);

    // Direction arrow inside beacon (pointing northwest ~315 deg)
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(beaconCenter.dx - 5, beaconCenter.dy - 6)
      ..lineTo(beaconCenter.dx + 6, beaconCenter.dy - 2)
      ..lineTo(beaconCenter.dx + 2, beaconCenter.dy + 6)
      ..lineTo(beaconCenter.dx - 1, beaconCenter.dy + 1)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, {required double fontSize, required Color color, bool isBold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

