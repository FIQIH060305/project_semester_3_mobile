import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex; // 0=Jadwal, 1=Progres, 2=Dashboard, 3=Notifikasi, 4=Profil
  const AppBottomNavBar({super.key, required this.currentIndex});

  void _navigasi(BuildContext context, int index) {
    if (index == currentIndex) return;

    final routes = ['/jadwal', '/progres', '/dashboard', '/notifikasi', '/profil'];
    Navigator.of(context).pushNamedAndRemoveUntil(routes[index], (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.calendar_month_rounded,
      Icons.bar_chart_rounded,
      Icons.directions_run_rounded,
      Icons.notifications_rounded,
      Icons.person_rounded,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(30),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(icons.length, (i) {
          final aktif = i == currentIndex;
          final isCenter = i == 2;

          final iconWidget = Icon(
            icons[i],
            color: aktif ? Colors.white : AppColors.textGrey,
            size: isCenter ? 26 : 22,
          );

          return GestureDetector(
            onTap: () => _navigasi(context, i),
            child: Container(
              padding: EdgeInsets.all(isCenter ? 12 : 8),
              decoration: BoxDecoration(
                color: aktif ? AppColors.brand : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            ),
          );
        }),
      ),
    );
  }
}