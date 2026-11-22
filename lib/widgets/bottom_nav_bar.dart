import 'package:flutter/material.dart';
import '../screens/sesi/sesi_olahraga_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex; // 0=Home, 1=Jadwal, 2=Tracking, 3=Progres, 4=Profile
  final ValueChanged<int>? onTap;

  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color accentSkyBlue = Color(0xFF0077E6);
  static const Color inactiveGrey = Color(0xFF94A3B8);
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
    final isTrackingActive = currentIndex == 2;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Container Bar Utama ────────────────────────────────────
          Container(
            height: 66,
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
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
                ),

                // Spacer untuk tombol tengah Tracking
                const SizedBox(width: 60),

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

          // ── 3. Tombol Tengah Tracking (Elevated Sport Button) ──────
          Positioned(
            top: -18,
            child: GestureDetector(
              onTap: () => _handleItemTap(context, 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isTrackingActive
                            ? const [Color(0xFF005BB5), Color(0xFF0077E6)]
                            : const [Color(0xFF0077E6), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentSkyBlue.withValues(
                              alpha: isTrackingActive ? 0.45 : 0.30),
                          blurRadius: isTrackingActive ? 14 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          isTrackingActive ? FontWeight.w800 : FontWeight.w700,
                      color: isTrackingActive ? primaryBlue : inactiveGrey,
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
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _handleItemTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 11, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primaryBlue : inactiveGrey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryBlue : inactiveGrey,
                fontSize: 10,
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
    final iconColor = isSelected ? primaryBlue : inactiveGrey;

    return GestureDetector(
      onTap: () => _handleItemTap(context, 3),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 11, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : Colors.transparent,
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
                      color:
                          iconColor.withValues(alpha: isSelected ? 0.85 : 0.65),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Progres',
              style: TextStyle(
                color: isSelected ? primaryBlue : inactiveGrey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}