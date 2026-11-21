import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;

class AppUser {
  final String id;
  String name;
  final String email;
  String? jenisKelamin;
  int? usia;
  double? tinggiBadan;
  double? beratBadan;
  String location;
  String? photoPath;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.jenisKelamin,
    this.usia,
    this.tinggiBadan,
    this.beratBadan,
    this.location = 'Jember, Indonesia',
    this.photoPath,
  });

  factory AppUser.fromJson(JsonMap json) {
    String? resolvedPhoto;
    final rawPhoto = json['foto_profil']?.toString();
    if (rawPhoto != null && rawPhoto.isNotEmpty && rawPhoto != 'null') {
      if (rawPhoto.startsWith('http') || rawPhoto.startsWith('/')) {
        resolvedPhoto = rawPhoto;
      } else {
        final host = AuthService.baseUrl.replaceAll('/api/mobile', '');
        resolvedPhoto = '$host/storage/$rawPhoto';
      }
    }

    return AppUser(
      id: (json['id_akun'] ?? json['id'] ?? '').toString(),
      name: (json['nama_lengkap'] ?? json['name'] ?? 'Pengguna GERAK').toString(),
      email: (json['email'] ?? '').toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      usia: json['usia'] != null ? int.tryParse(json['usia'].toString()) : null,
      tinggiBadan: json['tinggi_badan'] != null
          ? double.tryParse(json['tinggi_badan'].toString())
          : null,
      beratBadan: (json['berat_sekarang'] ?? json['berat_badan_awal']) != null
          ? double.tryParse(
              (json['berat_sekarang'] ?? json['berat_badan_awal']).toString())
          : null,
      photoPath: resolvedPhoto,
    );
  }

  JsonMap toJson() => {
        'id_akun': id,
        'nama_lengkap': name,
        'email': email,
        'jenis_kelamin': jenisKelamin,
        'usia': usia,
        'tinggi_badan': tinggiBadan,
        'berat_badan_awal': beratBadan,
        'foto_profil': photoPath,
      };
}

class AuthResult {
  final bool isSuccess;
  final String message;
  final AppUser? user;
  final String? token;

  AuthResult({
    required this.isSuccess,
    required this.message,
    this.user,
    this.token,
  });
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String baseUrl = 'http://192.168.1.11:8000/api/mobile';

  AppUser? currentUser;
  String? authToken;

  String? _pendingName;
  String? _pendingEmail;
  String? _pendingPassword;

  bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('gerak_auth_token');
    final savedUserJson = prefs.getString('gerak_user_json');

    if (savedToken != null && savedToken.isNotEmpty) {
      instance.authToken = savedToken;
      if (savedUserJson != null) {
        try {
          instance.currentUser = AppUser.fromJson(jsonDecode(savedUserJson));
        } catch (_) {}
      }
    }
  }

  Future<void> _persistSession(String? token, AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString('gerak_auth_token', token);
    } else {
      await prefs.remove('gerak_auth_token');
    }

    if (user != null) {
      await prefs.setString('gerak_user_json', jsonEncode(user.toJson()));
    } else {
      await prefs.remove('gerak_user_json');
    }
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  String _extractErrorMessage(JsonMap body, String fallback) {
    if (body['errors'] is Map) {
      final errors = body['errors'] as Map;
      if (errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return body['message']?.toString() ?? fallback;
  }

  // =========================================================================
  // 1. REGISTRASI 2 TAHAP
  // =========================================================================
  AuthResult register({
    required String name,
    required String email,
    required String password,
    String location = 'Jember, Indonesia',
    String? photoPath,
  }) {
    _pendingName = name.trim();
    _pendingEmail = email.trim().toLowerCase();
    _pendingPassword = password;
    return AuthResult(isSuccess: true, message: 'Langkah 1 berhasil.');
  }

  Future<AuthResult> completeRegistrationAndSync({
    required int usia,
    required String jenisKelaminLabel,
    required double tinggiBadan,
    required double beratBadan,
    required double targetBerat,
  }) async {
    if (_pendingName == null ||
        _pendingEmail == null ||
        _pendingPassword == null) {
      return AuthResult(
        isSuccess: false,
        message:
            'Data akun awal tidak ditemukan. Silakan ulangi dari halaman Daftar.',
      );
    }

    final kodeJenisKelamin =
        jenisKelaminLabel.toLowerCase().startsWith('l') ? 'L' : 'P';

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'nama_lengkap': _pendingName,
              'email': _pendingEmail,
              'password': _pendingPassword,
              'usia': usia,
              'jenis_kelamin': kodeJenisKelamin,
              'tinggi_badan': tinggiBadan,
              'berat_badan': beratBadan,
              'target_berat': targetBerat,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        authToken = body['token']?.toString();
        if (body['user'] is JsonMap) {
          currentUser = AppUser.fromJson(body['user'] as JsonMap);
        }
        await _persistSession(authToken, currentUser);

        _pendingName = null;
        _pendingEmail = null;
        _pendingPassword = null;
        notifyListeners();

        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ?? 'Akun berhasil dibuat!',
          user: currentUser,
          token: authToken,
        );
      }

      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(body, 'Registrasi gagal.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server Laravel.',
      );
    }
  }

  // =========================================================================
  // 2. LOGIN & LOGOUT
  // =========================================================================
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;

      if (response.statusCode == 200 && body['success'] == true) {
        authToken = body['token']?.toString();
        if (body['user'] is JsonMap) {
          currentUser = AppUser.fromJson(body['user'] as JsonMap);
        }
        await _persistSession(authToken, currentUser);
        notifyListeners();

        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ?? 'Berhasil masuk.',
          user: currentUser,
          token: authToken,
        );
      }

      return AuthResult(
        isSuccess: false,
        message:
            _extractErrorMessage(body, 'Email atau kata sandi tidak sesuai.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message:
            'Tidak dapat terhubung ke server. Periksa Wi-Fi dan IP server.',
      );
    }
  }

  Future<void> logout() async {
    currentUser = null;
    authToken = null;
    await _persistSession(null, null);
    notifyListeners();
  }

  bool updateProfile({String? name, String? location, String? photoPath}) {
    if (currentUser == null) return false;
    if (name != null && name.trim().isNotEmpty) currentUser!.name = name.trim();
    if (location != null && location.trim().isNotEmpty) {
      currentUser!.location = location.trim();
    }
    if (photoPath != null) {
      currentUser!.photoPath = photoPath.isEmpty ? null : photoPath;
    }
    _persistSession(authToken, currentUser);
    notifyListeners();
    return true;
  }

  // =========================================================================
  // 3. RESET PASSWORD OTP VIA EMAIL
  // =========================================================================
  Future<AuthResult> requestPasswordReset(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body) as JsonMap;
      if (response.statusCode == 200 && body['success'] == true) {
        return AuthResult(
          isSuccess: true,
          message:
              body['message']?.toString() ?? 'Kode verifikasi terkirim ke email.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(body, 'Email tidak terdaftar.'),
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    String? confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset-password'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': email.trim(),
              'otp': token.trim(),
              'password': newPassword,
              'password_confirmation': confirmPassword ?? newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;
      if (response.statusCode == 200 && body['success'] == true) {
        return AuthResult(
          isSuccess: true,
          message:
              body['message']?.toString() ?? 'Password berhasil diperbarui!',
        );
      }
      return AuthResult(
        isSuccess: false,
        message:
            _extractErrorMessage(body, 'Kode verifikasi salah atau kedaluwarsa.'),
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  void makeTokenExpiredForTesting(String email) {}

  // =========================================================================
  // 4. DATA DASBOR & SIMPAN AKTIVITAS LARI KE DATABASE LARAVEL
  // =========================================================================
  Future<JsonMap?> fetchDashboardData() async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is JsonMap) {
          final data = body['data'] as JsonMap;
          if (data['user'] is JsonMap && currentUser != null) {
            final u = data['user'] as JsonMap;
            final rawFoto = u['foto_profil']?.toString();
            if (rawFoto != null && rawFoto.isNotEmpty && rawFoto != 'null') {
              currentUser!.photoPath = rawFoto;
              await _persistSession(authToken, currentUser);
              notifyListeners();
            }
          }
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<AuthResult> simpanAktivitasKeServer({
    required String jenisOlahraga,
    required double jarakKm,
    required int durasiDetik,
    required int jumlahLangkah,
    required double kaloriTerbakar,
  }) async {
    if (!isLoggedIn) {
      return AuthResult(
        isSuccess: false,
        message: 'Sesi login berakhir, tersimpan secara lokal saja.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/aktivitas'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'jenis_olahraga': jenisOlahraga,
              'jarak_km': jarakKm,
              'durasi_detik': durasiDetik > 0 ? durasiDetik : 60,
              'jumlah_langkah': jumlahLangkah,
              'kalori_terbakar': kaloriTerbakar,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        return AuthResult(
          isSuccess: true,
          message:
              body['message']?.toString() ?? 'Aktivitas tersinkron ke server!',
        );
      }

      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(body, 'Gagal menyinkronkan ke server.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message: 'Offline: aktivitas disimpan di perangkat.',
      );
    }
  }

  // =========================================================================
  // 5. UPDATE PROFIL, UPLOAD FOTO & TARGET BERAT KE DATABASE LARAVEL
  // =========================================================================
  Future<AuthResult> syncProfileUpdateToServer({
    required String namaLengkap,
    required double tinggiBadan,
    required double beratBadan,
    required double beratTarget,
    String? location,
    String? photoPath,
  }) async {
    updateProfile(name: namaLengkap, location: location, photoPath: photoPath);

    if (!isLoggedIn) {
      return AuthResult(
        isSuccess: true,
        message: 'Profil diperbarui secara lokal.',
      );
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/update'),
      );

      request.headers['Accept'] = 'application/json';
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      request.fields['nama_lengkap'] = namaLengkap.trim();
      request.fields['tinggi_badan'] = tinggiBadan.toString();
      request.fields['berat_badan'] = beratBadan.toString();
      request.fields['berat_target'] = beratTarget.toString();

      if (photoPath != null && photoPath.isEmpty) {
        request.fields['hapus_foto'] = '1';
      } else if (photoPath != null &&
          photoPath.isNotEmpty &&
          !photoPath.startsWith('http')) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_profil', photoPath),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as JsonMap;

      if (response.statusCode == 200 && body['success'] == true) {
        if (body['user'] is JsonMap) {
          currentUser = AppUser.fromJson(body['user'] as JsonMap);
        } else if (currentUser != null) {
          currentUser!.tinggiBadan = tinggiBadan;
          currentUser!.beratBadan = beratBadan;
        }
        await _persistSession(authToken, currentUser);
        notifyListeners();

        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ??
              'Profil & foto berhasil disimpan ke server!',
        );
      }

      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(
            body, 'Gagal memperbarui profil ke server.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message: 'Tersimpan lokal (gagal mengunggah ke server).',
      );
    }
  }

  // =========================================================================
  // 6. AMBIL RIWAYAT OLAHRAGA USER DARI DATABASE LARAVEL
  // =========================================================================
  Future<List<JsonMap>> fetchRiwayatOlahraga() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/aktivitas'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is List) {
          return List<JsonMap>.from(body['data'] as List);
        }
      }
    } catch (_) {}
    return [];
  }
  // =========================================================================
  // 7. JADWAL OLAHRAGA, NOTIFIKASI & KONTEN EDUKASI DARI DATABASE LARAVEL
  // =========================================================================
  Future<List<JsonMap>> fetchJadwalList() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/jadwal'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is List) {
          return List<JsonMap>.from(body['data'] as List);
        }
      }
    } catch (_) {}
    return [];
  }

  Future<JsonMap?> createJadwalOnServer({
    required String tugas,
    required DateTime tanggalTugas,
    String jenisOlahraga = 'Lari',
  }) async {
    if (!isLoggedIn) return null;
    try {
      final tglStr =
          '${tanggalTugas.year.toString().padLeft(4, '0')}-${tanggalTugas.month.toString().padLeft(2, '0')}-${tanggalTugas.day.toString().padLeft(2, '0')}';

      final response = await http
          .post(
            Uri.parse('$baseUrl/jadwal'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'tugas': tugas,
              'jenis_olahraga': jenisOlahraga,
              'tanggal_tugas': tglStr,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is JsonMap) {
          return body['data'] as JsonMap;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool?> toggleJadwalOnServer(String idJadwal) async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/jadwal/$idJadwal/toggle'),
            headers: _jsonHeaders,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true) {
          return body['selesai'] == true;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteJadwalOnServer(String idJadwal) async {
    if (!isLoggedIn) return false;
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/jadwal/$idJadwal'),
            headers: _jsonHeaders,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        return body['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<JsonMap>> fetchNotifikasiList() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/notifikasi'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is List) {
          return List<JsonMap>.from(body['data'] as List);
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> markNotifikasiReadOnServer() async {
    if (!isLoggedIn) return;
    try {
      await http
          .post(
            Uri.parse('$baseUrl/notifikasi/baca'),
            headers: _jsonHeaders,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<List<JsonMap>> fetchEdukasiList() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/edukasi'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is List) {
          return List<JsonMap>.from(body['data'] as List);
        }
      }
    } catch (_) {}
    return [];
  }
  // =========================================================================
  // 8. PEMANTAUAN PROGRES BERAT BADAN MINGGUAN (SENIN - MINGGU)
  // =========================================================================
  Future<JsonMap?> fetchWeeklyWeightProgress({int weekOffset = 0}) async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/berat-badan/mingguan?week_offset=$weekOffset'),
            headers: _jsonHeaders,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is JsonMap) {
          return body['data'] as JsonMap;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<AuthResult> recordDailyWeight({
    required double beratBadan,
    DateTime? tanggal,
  }) async {
    if (!isLoggedIn) {
      return AuthResult(
        isSuccess: false,
        message: 'Silakan masuk kembali untuk mencatat berat badan.',
      );
    }

    try {
      final payload = <String, dynamic>{
        'berat_badan': beratBadan,
      };
      if (tanggal != null) {
        payload['tanggal_pencatatan'] =
            '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/berat-badan/catat'),
            headers: _jsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body) as JsonMap;
      if (response.statusCode == 200 && body['success'] == true) {
        final today = DateTime.now();
        final isToday = tanggal == null ||
            (tanggal.year == today.year &&
                tanggal.month == today.month &&
                tanggal.day == today.day);
        if (isToday && currentUser != null) {
          currentUser!.beratBadan = beratBadan;
          await _persistSession(authToken, currentUser);
          notifyListeners();
        }

        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ?? 'Berat badan berhasil dicatat!',
        );
      }

      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(body, 'Gagal menyimpan berat badan.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message: 'Tidak dapat terhubung ke server Laravel.',
      );
    }
  }
}
