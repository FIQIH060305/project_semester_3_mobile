import 'package:flutter/material.dart';
import '../screens/sesi/sesi_olahraga_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex; // 0=Home/Dashboard, 1=Jadwal, 2=Tracking, 3=Progres, 4=Profile
  final ValueChanged<int>? onTap;

  static const Color primaryBlue = Color(0xFF0063A8);
  static const Color inactiveGrey = Color(0xFF9E9E9E);
  static const Color navBg = Colors.white;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleItemTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Fallback jika BottomNavBar dipanggil tanpa callback onTap (navigasi langsung)
    if (index == currentIndex) return;

    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SesiOlahragaScreen()),
      );
      return;
    }

    final routes = {
      0: '/dashboard',
      1: '/jadwal',
      3: '/progres',
      4: '/profil',
    };

    final route = routes[index];
    if (route != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Container Bar Utama ────────────────────────────────────
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home (index 0)
                _buildNavItem(
                  context,
                  index: 0,
                  label: 'Home',
                  activeIcon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                ),

                // 2. Jadwal (index 1)
                _buildNavItem(
                  context,
                  index: 1,
                  label: 'Jadwal',
                  activeIcon: Icons.calendar_month_rounded,
                  inactiveIcon: Icons.calendar_month_outlined,
                  showClockBadge: true,
                ),

                // Spacer untuk tombol tengah Tracking
                const SizedBox(width: 52),

                // 4. Progres (index 3)
                _buildProgresItem(context),

                // 5. Profile (index 4)
                _buildNavItem(
                  context,
                  index: 4,
                  label: 'Profile',
                  activeIcon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outlined,
                ),
              ],
            ),
          ),

          // ── 3. Tombol Tengah Tracking (Elevated Floating Button) ──
          Positioned(
            top: -18,
            child: GestureDetector(
              onTap: () => _handleItemTap(context, 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: currentIndex == 2
                          ? primaryBlue
                          : const Color(0xFF4B8EE5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (currentIndex == 2
                                  ? primaryBlue
                                  : const Color(0xFF4B8EE5))
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: currentIndex == 2 ? FontWeight.w800 : FontWeight.w600,
                      color: currentIndex == 2 ? primaryBlue : inactiveGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav Item Biasa (Home, Jadwal, Profile) ──────────────────────────
  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    bool showClockBadge = false,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _handleItemTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            showClockBadge && !isSelected
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(inactiveIcon, color: inactiveGrey, size: 22),
                      Positioned(
                        right: -3,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(1.2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_filled_rounded,
                            size: 10,
                            color: inactiveGrey,
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected ? Colors.white : inactiveGrey,
                    size: 22,
                  ),
            const SizedBox(height: 1.5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : inactiveGrey,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progres Item dengan Ikon Bar Vertikal ─────────────────────────
  Widget _buildProgresItem(BuildContext context) {
    final isSelected = currentIndex == 3;
    final iconColor = isSelected ? Colors.white : inactiveGrey;

    return GestureDetector(
      onTap: () => _handleItemTap(context, 3),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 22,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 3.5,
                    height: 12,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 2.5),
                  Container(
                    width: 3.5,
                    height: 18,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 2.5),
                  Container(
                    width: 3.5,
                    height: 9,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isSelected ? 0.8 : 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1.5),
            Text(
              'Progres',
              style: TextStyle(
                color: isSelected ? Colors.white : inactiveGrey,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
