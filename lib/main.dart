import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_colors.dart';
import 'core/app_typography.dart';
import 'services/auth_service.dart';
import 'services/jadwal_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registrasi_screen.dart';
import 'screens/auth/lupa_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'screens/profil/edit_profil_screen.dart';
import 'screens/coach/registrasi_coach_screen.dart';
import 'screens/coach/coach_verifikasi_screen.dart';
import 'screens/coach/coach_main_screen.dart';
import 'screens/user/user_coach_screen.dart';
import 'screens/user/user_diet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await AuthService.initialize();
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
        textTheme: AppTypography.textTheme,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
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
        '/registrasi-coach': (_) => const RegistrasiCoachScreen(),
        '/coach-verifikasi': (_) => const CoachVerifikasiScreen(),
        '/coach-dashboard': (_) => const CoachMainScreen(),
        '/user-coach': (_) => const UserCoachScreen(),
        '/user-diet': (_) => const UserDietScreen(),
      },
    );
  }
}