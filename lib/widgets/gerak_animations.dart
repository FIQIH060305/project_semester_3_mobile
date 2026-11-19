import 'package:flutter/material.dart';

/// 1. Animasi Masuk Bertahap (Fade + Slide Up Halus) untuk Card & Elemen UI
class GerakEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Offset beginOffset;

  const GerakEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<GerakEntrance> createState() => _GerakEntranceState();
}

class _GerakEntranceState extends State<GerakEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// 2. Animasi Radar / Denyut Energi untuk Tombol Mulai Lari & Tracking Aktif
class GerakPulseBeacon extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final bool isActive;

  const GerakPulseBeacon({
    super.key,
    required this.child,
    this.pulseColor = const Color(0xFF0B5A9E),
    this.isActive = true,
  });

  @override
  State<GerakPulseBeacon> createState() => _GerakPulseBeaconState();
}

class _GerakPulseBeaconState extends State<GerakPulseBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant GerakPulseBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.22);
        final opacity = (1.0 - _controller.value).clamp(0.0, 0.45);
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isActive)
              Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.pulseColor.withValues(alpha: opacity),
                  ),
                ),
              ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// 3. Animasi Angka Menghitung Naik (Langkah, Jarak KM, Kalori)
class GerakAnimatedMetric extends StatelessWidget {
  final double targetValue;
  final int fractionDigits;
  final String suffix;
  final TextStyle style;

  const GerakAnimatedMetric({
    super.key,
    required this.targetValue,
    this.fractionDigits = 0,
    this.suffix = '',
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutExpo,
      builder: (context, value, _) {
        final formatted = fractionDigits == 0
            ? value.round().toString()
            : value.toStringAsFixed(fractionDigits);
        return Text('$formatted$suffix', style: style);
      },
    );
  }
}