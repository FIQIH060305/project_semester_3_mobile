import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_colors.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/jadwal/jadwal_screen.dart';
import 'screens/riwayat/riwayat_olahraga_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'screens/placeholder_screen.dart';

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
      initialRoute: '/dashboard',
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/jadwal': (_) => const JadwalScreen(),
        '/progres': (_) => const RiwayatOlahragaScreen(),
        '/notifikasi': (_) => const NotifikasiScreen(),
        '/profil': (_) => const PlaceholderScreen(judul: 'Profil', navIndex: 4),
      },
    );
  }
}