import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/auth_service.dart';

void main() {
  group('AuthService API Contract Tests', () {
    test('Registrasi tahap 1 menyimpan data sementara dan mengembalikan sukses', () {
      final result = AuthService.instance.register(
        name: 'Pengguna Uji',
        email: 'uji@gerak.id',
        password: 'password123',
      );
      expect(result.isSuccess, isTrue);
    });

    test('Status awal belum login sebelum autentikasi ke server', () {
      expect(AuthService.instance.isLoggedIn, isFalse);
    });
  });
}