import 'package:flutter/material.dart';
import '../screens/sesi/sesi_olahraga_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex; // 0=Home/Dashboard, 1=Jadwal, 2=Tracking, 3=Progres, 4=Profile
  const AppBottomNavBar({super.key, required this.currentIndex});

  void _navigasi(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 2) {
      // Tracking diarahkan ke Sesi Olahraga
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
          // Container bar utama
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _buildHomeItem(context),

                // 2. Jadwal
                _buildStandardItem(
                  context,
                  index: 1,
                  label: 'Jadwal',
                  icon: Icons.calendar_month_outlined,
                  showClockBadge: true,
                ),

                // Spacer untuk tombol tengah Tracking
                const SizedBox(width: 52),

                // 4. Progres
                _buildProgresItem(context),

                // 5. Profile
                _buildStandardItem(
                  context,
                  index: 4,
                  label: 'Profile',
                  icon: Icons.person_rounded,
                ),
              ],
            ),
          ),

          // 3. Tombol Tengah Tracking (Elevated Floating Pill)
          Positioned(
            top: -18,
            child: GestureDetector(
              onTap: () => _navigasi(context, 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6DA7F2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4B8EE5).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
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

  Widget _buildHomeItem(BuildContext context) {
    final isHome = currentIndex == 0;

    return GestureDetector(
      onTap: () => _navigasi(context, 0),
      child: isHome
          ? Container(
              width: 48,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E5B99),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_rounded, color: Colors.white, size: 22),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, color: Color(0xFF60A5FA), size: 24),
                SizedBox(height: 2),
                Text(
                  'Home',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStandardItem(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
    bool showClockBadge = false,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF1E5B99) : const Color(0xFF60A5FA);

    return GestureDetector(
      onTap: () => _navigasi(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          showClockBadge
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 24),
                    Positioned(
                      right: -3,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time_filled_rounded,
                            size: 11, color: color),
                      ),
                    ),
                  ],
                )
              : Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E5B99) : const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresItem(BuildContext context) {
    final isSelected = currentIndex == 3;
    final color = isSelected ? const Color(0xFF1E5B99) : const Color(0xFF60A5FA);

    return GestureDetector(
      onTap: () => _navigasi(context, 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2.5),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2.5),
              Container(
                width: 4,
                height: 10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Progres',
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E5B99) : const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}