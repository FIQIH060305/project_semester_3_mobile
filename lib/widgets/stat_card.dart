import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final String label;
  final int nilai;
  final int target;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.label,
    required this.nilai,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final progres = target == 0 ? 0.0 : (nilai / target).clamp(0.0, 1.0);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('$nilai',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progres,
                minHeight: 6,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
            const SizedBox(height: 6),
            Text('Target $target',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}