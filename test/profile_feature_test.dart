import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/profil/profil_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/profil/edit_profil_screen.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService.initialize();
    AuthService.instance.login(
      email: 'fiqih@gerak.id',
      password: 'Password123!',
    );
    AuthService.instance.updateProfile(
      name: 'Fiqih Al Firdaus',
      location: 'Jember,  Indonesia',
      photoPath: '',
    );
  });

  group('Pengujian Logika Fitur Profile & Logout', () {
    test('1. Nilai profil awal pengguna terisi dengan benar', () {
      final user = AuthService.instance.currentUser;
      expect(user, isNotNull);
      expect(user!.name, equals('Fiqih Al Firdaus'));
      expect(user.location, contains('Jember'));
    });

    test('2. Update profil berhasil mengubah nama, domisili, dan foto', () {
      final updated = AuthService.instance.updateProfile(
        name: 'Fiqih Al Firdaus Updated',
        location: 'Surabaya, Indonesia',
        photoPath: '/mock/path/profile.jpg',
      );

      expect(updated, isTrue);
      final user = AuthService.instance.currentUser;
      expect(user!.name, equals('Fiqih Al Firdaus Updated'));
      expect(user.location, equals('Surabaya, Indonesia'));
      expect(user.photoPath, equals('/mock/path/profile.jpg'));
    });

    test('3. Logout berhasil mengosongkan sesi pengguna aktif', () {
      expect(AuthService.instance.currentUser, isNotNull);

      AuthService.instance.logout();

      expect(AuthService.instance.currentUser, isNull);
    });

    test('4. Setelah logout, pengguna dapat login kembali dan data tetap sinkron', () {
      AuthService.instance.logout();
      expect(AuthService.instance.currentUser, isNull);

      final loginRes = AuthService.instance.login(
        email: 'fiqih@gerak.id',
        password: 'Password123!',
      );

      expect(loginRes.isSuccess, isTrue);
      expect(AuthService.instance.currentUser, isNotNull);
      expect(AuthService.instance.currentUser!.email, equals('fiqih@gerak.id'));
    });
  });

  group('Pengujian Widget Halaman Profile & Dialog Logout', () {
    testWidgets('5. Halaman Profil menampilkan data pengguna, tombol edit, dan tombol logout',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfilScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan elemen utama profil muncul
      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
      expect(find.text('Fiqih Al Firdaus'), findsOneWidget);
      expect(find.text('Jember,  Indonesia'), findsOneWidget);
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('TOTAL JARAK'), findsOneWidget);
      expect(find.text('Target Lari Mingguan'), findsOneWidget);
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });

    testWidgets('6. Dialog konfirmasi logout muncul dengan pertanyaan dan tombol Batal/Ya, Keluar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('Halaman Login')),
          },
          home: const ProfilScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll ke bawah agar tombol logout terlihat
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Ketuk tombol logout card
      final logoutButton = find.text('Keluar dari Akun');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Periksa isi dialog
      expect(find.text('Keluar Akun'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin keluar dari akun?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);

      // Coba tekan Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog tertutup dan masih berada di Profil
      expect(find.text('Apakah Anda yakin ingin keluar dari akun?'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
    });

    testWidgets('7. Halaman Edit Profil memuat nilai awal dan validasi nama wajib diisi',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditProfilScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Lokasi / Domisili'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Kosongkan nama untuk menguji validasi
      final namaField = find.byType(TextFormField).first;
      await tester.enterText(namaField, '');
      await tester.pumpAndSettle();

      // Ketuk Simpan Perubahan
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Pesan error validasi muncul
      expect(find.text('Nama lengkap tidak boleh kosong'), findsOneWidget);
    });
  });
}
