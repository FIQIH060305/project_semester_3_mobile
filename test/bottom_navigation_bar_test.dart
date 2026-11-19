import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/main_navigation_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/widgets/bottom_nav_bar.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/sesi/pelacakan_aktif_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/riwayat/detail_riwayat_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/profil/edit_profil_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/jadwal/tambah_tugas_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/models/riwayat_item.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/auth_service.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/jadwal_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    AuthService.initialize();
    JadwalService.instance.initialize();
  });

  group('Pengujian Sistem Navigasi Bawah (Bottom Navigation Bar)', () {
    testWidgets('1. Menampilkan 5 menu utama dengan ikon dan label yang sesuai',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(initialIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Periksa keberadaan 5 menu di Bottom Navigation Bar
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Jadwal'), findsOneWidget);
      expect(find.text('Tracking'), findsOneWidget);
      expect(find.text('Progres'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('2. Berpindah antar tab menggunakan IndexedStack tanpa mereset halaman',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(initialIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Awalnya di tab Home (index 0)
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      IndexedStack stack = tester.widget(indexedStackFinder);
      expect(stack.index, equals(0));

      // 2. Ketuk tab Jadwal
      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();

      stack = tester.widget(indexedStackFinder);
      expect(stack.index, equals(1));
      expect(find.text('Buat jadwalmu sendiri'), findsOneWidget);

      // 3. Ketuk tab Progres
      await tester.tap(find.text('Progres'));
      await tester.pumpAndSettle();

      stack = tester.widget(indexedStackFinder);
      expect(stack.index, equals(3));
      expect(find.text('Riwayat Olahraga'), findsOneWidget);

      // 4. Ketuk tab Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      stack = tester.widget(indexedStackFinder);
      expect(stack.index, equals(4));
      expect(find.text('Fiqih Al Firdaus'), findsOneWidget);

      // 5. Ketuk tab Tracking (tengah)
      await tester.tap(find.text('Tracking'));
      await tester.pumpAndSettle();

      stack = tester.widget(indexedStackFinder);
      expect(stack.index, equals(2));
      expect(find.text('Sesi Olahraga'), findsOneWidget);
    });

    testWidgets('3. Aturan Tombol Back: Kembali ke Home jika di selain Home',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(initialIndex: 1), // Mulai di Jadwal
        ),
      );
      await tester.pumpAndSettle();

      IndexedStack stack = tester.widget(find.byType(IndexedStack));
      expect(stack.index, equals(1));

      // Simulasikan tombol Android Back ditekan
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Harus otomatis berpindah kembali ke Home (index 0)
      stack = tester.widget(find.byType(IndexedStack));
      expect(stack.index, equals(0));
    });

    testWidgets('4. Aturan Tombol Back di Home: Menampilkan dialog konfirmasi keluar aplikasi',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(initialIndex: 0), // Di Home
        ),
      );
      await tester.pumpAndSettle();

      // Simulasikan tombol Android Back ditekan
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Dialog konfirmasi keluar muncul
      expect(find.text('Keluar Aplikasi'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin keluar dari aplikasi GERAK?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Tekan Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Tetap di Home
      expect(find.text('Keluar Aplikasi'), findsNothing);
      final IndexedStack stack = tester.widget(find.byType(IndexedStack));
      expect(stack.index, equals(0));
    });

    testWidgets('5. Subhalaman dan Tracking Aktif TIDAK menampilkan Bottom Navigation Bar',
        (tester) async {
      // 1. EditProfilScreen tidak punya BottomNavBar
      await tester.pumpWidget(
        const MaterialApp(
          home: EditProfilScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsNothing);

      // 2. TambahTugasScreen tidak punya BottomNavBar
      await tester.pumpWidget(
        const MaterialApp(
          home: TambahTugasScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsNothing);

      // 3. DetailRiwayatScreen tidak punya BottomNavBar
      await tester.pumpWidget(
        MaterialApp(
          home: DetailRiwayatScreen(
            item: dataDummyRiwayat().first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNavBar), findsNothing);

      // 4. PelacakanAktifScreen (Tracking Aktif) tidak punya BottomNavBar
      await tester.pumpWidget(
        const MaterialApp(
          home: PelacakanAktifScreen(jenisOlahraga: 'Berlari'),
        ),
      );
      await tester.pump();
      expect(find.byType(AppBottomNavBar), findsNothing);
    });

    test('6. Konsistensi Warna Navigasi sesuai aturan', () {
      expect(AppBottomNavBar.primaryBlue, equals(const Color(0xFF0063A8)));
      expect(AppBottomNavBar.inactiveGrey, equals(const Color(0xFF9E9E9E)));
      expect(AppBottomNavBar.navBg, equals(Colors.white));
    });
  });
}
