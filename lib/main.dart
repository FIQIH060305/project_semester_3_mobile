import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_colors.dart';
// Import halaman auth milikmu
import 'screens/auth/login_screen.dart';
import 'screens/auth/registrasi_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/jadwal/jadwal_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/riwayat/riwayat_olahraga_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const GerakApp());
}

class GerakApp extends StatelessWidget {
  const GerakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GERAK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.brand,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
      ),
      // Ubah route awal ke '/login' (atau '/splash' jika ingin splash screen dulu)
      initialRoute: '/login',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/registrasi': (_) => const RegistrasiScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/jadwal': (_) => const JadwalScreen(),
        '/progres': (_) => const RiwayatOlahragaScreen(),
        '/notifikasi': (_) => const PlaceholderScreen(judul: 'Notifikasi', navIndex: 3),
        '/profil': (_) => const PlaceholderScreen(judul: 'Profil', navIndex: 4),
      },
    );
  }
}