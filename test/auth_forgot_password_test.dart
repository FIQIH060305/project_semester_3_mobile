import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/auth_service.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/screens/utils/validators.dart';

void main() {
  setUp(() {
    AuthService.initialize();
  });

  group('Pengujian Fitur Lupa Password & Autentikasi', () {
    // 1. Pengguna memasukkan email yang terdaftar
    test('1. Pengguna memasukkan email yang terdaftar -> berhasil menerima token reset', () {
      final result = AuthService.instance.requestPasswordReset('fiqih@gerak.id');

      expect(result.isSuccess, isTrue);
      expect(result.resetToken, isNotNull);
      expect(result.resetToken!.length, equals(6));
      expect(result.message, contains('berhasil dikirim'));
    });

    // 2. Pengguna memasukkan email yang tidak terdaftar
    test('2. Pengguna memasukkan email yang tidak terdaftar -> ditolak dengan aman', () {
      final result = AuthService.instance.requestPasswordReset('tidak_terdaftar@domain.com');

      expect(result.isSuccess, isFalse);
      expect(result.resetToken, isNull);
      expect(result.message, contains('tidak terdaftar'));
    });

    // 3. Pengguna memasukkan email dengan format tidak valid
    test('3. Pengguna memasukkan format email tidak valid -> validator menolak', () {
      expect(Validators.email(null), equals('Alamat email wajib diisi'));
      expect(Validators.email(''), equals('Alamat email wajib diisi'));
      expect(Validators.email('invalid-email'), equals('Format email tidak valid'));
      expect(Validators.email('user@'), equals('Format email tidak valid'));
      expect(Validators.email('@domain.com'), equals('Format email tidak valid'));
      expect(Validators.email('valid.email@domain.com'), isNull);
    });

    // 4. Pengguna membuka tautan/token reset yang sudah kedaluwarsa
    test('4. Token reset yang sudah kedaluwarsa ditolak saat verifikasi/reset', () {
      final reqResult = AuthService.instance.requestPasswordReset('user@gmail.com');
      expect(reqResult.isSuccess, isTrue);
      final token = reqResult.resetToken!;

      // Simulasikan token kedaluwarsa
      AuthService.instance.makeTokenExpiredForTesting('user@gmail.com', token);

      // Coba reset dengan token yang sudah kedaluwarsa
      final resetResult = AuthService.instance.resetPassword(
        email: 'user@gmail.com',
        token: token,
        newPassword: 'NewPassword123!',
      );

      expect(resetResult.isSuccess, isFalse);
      expect(resetResult.message.toLowerCase(), contains('kedaluwarsa'));
    });

    // 5. Pengguna memasukkan password baru yang tidak sama dengan konfirmasi
    test('5. Validasi konfirmasi password tidak sama -> ditolak', () {
      final validator = Validators.confirmPassword('PasswordBaru123');
      expect(
        validator('PasswordBeda456'),
        equals('Konfirmasi kata sandi tidak sama'),
      );
      expect(
        validator('PasswordBaru123'),
        isNull,
      );
    });

    // 6. Pengguna berhasil mengganti password (dan token tidak dapat digunakan kembali)
    test('6. Pengguna berhasil mengganti password dan token sekali pakai dinonaktifkan', () {
      const email = 'fiqih@gerak.id';
      final reqResult = AuthService.instance.requestPasswordReset(email);
      expect(reqResult.isSuccess, isTrue);
      final token = reqResult.resetToken!;

      // Reset password baru
      final resetResult = AuthService.instance.resetPassword(
        email: email,
        token: token,
        newPassword: 'MyNewSuperPassword123!',
      );

      expect(resetResult.isSuccess, isTrue);
      expect(resetResult.message, contains('berhasil diatur ulang'));

      // Coba pakai token yang sama untuk kedua kalinya (harus ditolak karena 1x pakai)
      final reuseResult = AuthService.instance.resetPassword(
        email: email,
        token: token,
        newPassword: 'AnotherPassword123!',
      );
      expect(reuseResult.isSuccess, isFalse);
      expect(reuseResult.message, contains('sudah pernah digunakan'));
    });

    // 7. Pengguna mencoba login menggunakan password lama vs password baru
    test('7. Login dengan password lama gagal, dan login dengan password baru berhasil', () {
      const email = 'fiqih@gerak.id';

      // 1. Password lama ditolak
      final oldLoginResult = AuthService.instance.login(
        email: email,
        password: 'Password123!', // Password sebelum reset di test 6
      );
      expect(oldLoginResult.isSuccess, isFalse);
      expect(oldLoginResult.message, contains('tidak sesuai'));

      // 2. Password baru diterima
      final newLoginResult = AuthService.instance.login(
        email: email,
        password: 'MyNewSuperPassword123!', // Password baru yang diset di test 6
      );
      expect(newLoginResult.isSuccess, isTrue);
      expect(newLoginResult.user, isNotNull);
      expect(newLoginResult.user!.email, equals(email));
    });
  });
}
