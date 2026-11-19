import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project_semester3_mobileapp_gerak/services/auth_service.dart';

void main() {
  test('Update profil lokal memperbarui data pengguna saat aktif', () {
    AuthService.instance.currentUser = AppUser(
      id: '1',
      name: 'Sobat GERAK',
      email: 'sobat@gerak.id',
    );

    final updated = AuthService.instance.updateProfile(
      name: 'Fiqih Al Firdaus',
      location: 'Jember, Indonesia',
    );

    expect(updated, isTrue);
    expect(AuthService.instance.currentUser?.name, 'Fiqih Al Firdaus');
  });
}