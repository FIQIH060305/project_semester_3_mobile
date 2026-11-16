import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard/dashboard_screen.dart';
import 'jadwal/jadwal_screen.dart';
import 'sesi/sesi_olahraga_screen.dart';
import 'riwayat/riwayat_olahraga_screen.dart';
import 'profil/profil_screen.dart';

/// InheritedWidget untuk memfasilitasi perpindahan tab dari child widget manapun
class MainNavigationController extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> switchTab;

  const MainNavigationController({
    super.key,
    required this.currentIndex,
    required this.switchTab,
    required super.child,
  });

  static MainNavigationController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavigationController>();
  }

  @override
  bool updateShouldNotify(MainNavigationController oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

/// Halaman induk navigasi aplikasi GERAK
///
/// Menggunakan [IndexedStack] agar seluruh 5 halaman utama mempertahankan
/// state, posisi scroll, dan kondisi data saat berpindah tab.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.exit_to_app_rounded, color: AppBottomNavBar.primaryBlue, size: 24),
            SizedBox(width: 10),
            Text(
              'Keluar Aplikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi GERAK?',
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppBottomNavBar.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationController(
      currentIndex: _currentIndex,
      switchTab: _onTabTapped,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // 1. Jika pengguna berada di selain Home, tekan Back kembali ke Home
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            return;
          }

          // 2. Jika sudah di Home, tampilkan dialog konfirmasi keluar aplikasi
          final keluar = await _showExitDialog(context);
          if (keluar && context.mounted) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardScreen(showBottomNav: false),
              JadwalScreen(showBottomNav: false),
              SesiOlahragaScreen(showBottomNav: false),
              RiwayatOlahragaScreen(showBottomNav: false),
              ProfilScreen(showBottomNav: false),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}
