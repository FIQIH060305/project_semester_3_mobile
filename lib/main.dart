import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_colors.dart';
import 'services/auth_service.dart';
import 'services/jadwal_service.dart';
// Import halaman auth milikmu
import 'screens/auth/login_screen.dart';
import 'screens/auth/registrasi_screen.dart';
import 'screens/auth/lupa_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/jadwal/jadwal_screen.dart';
import 'screens/riwayat/riwayat_olahraga_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'screens/sesi/sesi_olahraga_screen.dart';
import 'screens/profil/profil_screen.dart';
import 'screens/profil/edit_profil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  AuthService.initialize();
  JadwalService.instance.initialize();
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
      // Alur: Splash → Login → Registrasi → Lengkapi Profil → Profil Berhasil → Login
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/registrasi': (_) => const RegistrasiScreen(),
        '/lupa-password': (_) => const LupaPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(email: ''),
        '/dashboard': (_) => const MainNavigationScreen(initialIndex: 0),
        '/jadwal': (_) => const MainNavigationScreen(initialIndex: 1),
        '/tracking': (_) => const MainNavigationScreen(initialIndex: 2),
        '/progres': (_) => const MainNavigationScreen(initialIndex: 3),
        '/notifikasi': (_) => const NotifikasiScreen(),
        '/profil': (_) => const MainNavigationScreen(initialIndex: 4),
        '/edit-profil': (_) => const EditProfilScreen(),
      },
    );
  }
}