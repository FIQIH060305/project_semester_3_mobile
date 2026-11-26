import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonMap = Map<String, dynamic>;

class CoachProfile {
  final String id;
  String nama;
  String tempatLahir;
  String tanggalLahir;
  int usia;
  String noHp;
  String? spesialisasi;
  String? bio;
  String statusVerifikasi; // 'pending', 'approved', 'rejected'
  String? alasanPenolakan;

  CoachProfile({
    required this.id,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.usia,
    required this.noHp,
    this.spesialisasi,
    this.bio,
    this.statusVerifikasi = 'pending',
    this.alasanPenolakan,
  });

  factory CoachProfile.fromJson(JsonMap json) {
    return CoachProfile(
      id: (json['id'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      tempatLahir: (json['tempat_lahir'] ?? '').toString(),
      tanggalLahir: (json['tanggal_lahir'] ?? '').toString(),
      usia: int.tryParse((json['usia'] ?? '0').toString()) ?? 0,
      noHp: (json['no_hp'] ?? '').toString(),
      spesialisasi: json['spesialisasi']?.toString(),
      bio: json['bio']?.toString(),
      statusVerifikasi:
          (json['status_verifikasi'] ?? 'pending').toString().toLowerCase(),
      alasanPenolakan: json['alasan_penolakan']?.toString(),
    );
  }

  JsonMap toJson() => {
        'id': id,
        'nama': nama,
        'tempat_lahir': tempatLahir,
        'tanggal_lahir': tanggalLahir,
        'usia': usia,
        'no_hp': noHp,
        'spesialisasi': spesialisasi,
        'bio': bio,
        'status_verifikasi': statusVerifikasi,
        'alasan_penolakan': alasanPenolakan,
      };
}

class AppUser {
  final String id;
  String name;
  final String email;
  String role; // 'user' | 'coach'
  CoachProfile? coach;
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
    this.role = 'user',
    this.coach,
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

    CoachProfile? parsedCoach;
    final rawCoach = json['coach'] ?? json['coach_profile'];
    if (rawCoach is JsonMap) {
      parsedCoach = CoachProfile.fromJson(rawCoach);
    }

    return AppUser(
      id: (json['id_akun'] ?? json['id'] ?? '').toString(),
      name: (json['nama_lengkap'] ??
              parsedCoach?.nama ??
              json['name'] ??
              'Pengguna GERAK')
          .toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? (parsedCoach != null ? 'coach' : 'user'))
          .toString()
          .toLowerCase(),
      coach: parsedCoach,
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
        'role': role,
        if (coach != null) 'coach': coach!.toJson(),
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

  static const String baseUrl = 'http://192.168.1.7:8000/api/mobile';

  AppUser? currentUser;
  String? authToken;
  String lastCoachClientsDebug = 'Belum memanggil /coach/klien';

  String? _pendingName;
  String? _pendingEmail;
  String? _pendingPassword;

  bool get isLoggedIn => authToken != null && authToken!.isNotEmpty;
  bool get isCoach => currentUser?.role == 'coach';
  bool get isCoachApproved =>
      isCoach && currentUser?.coach?.statusVerifikasi == 'approved';

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
  // 1. REGISTRASI PESERTA (2 TAHAP) & REGISTRASI PELATIH
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

  Future<AuthResult> registerCoach({
    required String nama,
    required String tempatLahir,
    required DateTime tanggalLahir,
    required String noHp,
    required String email,
    required String password,
    String? spesialisasi,
    String? bio,
  }) async {
    final tglStr =
        '${tanggalLahir.year.toString().padLeft(4, '0')}-${tanggalLahir.month.toString().padLeft(2, '0')}-${tanggalLahir.day.toString().padLeft(2, '0')}';

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register-coach'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'nama': nama.trim(),
              'nama_lengkap': nama.trim(),
              'tempat_lahir': tempatLahir.trim(),
              'tanggal_lahir': tglStr,
              'no_hp': noHp.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
              'password_confirmation': password,
              if (spesialisasi != null && spesialisasi.trim().isNotEmpty)
                'spesialisasi': spesialisasi.trim(),
              if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          body['success'] == true) {
        authToken = body['token']?.toString();
        if (body['user'] is JsonMap) {
          final userMap = Map<String, dynamic>.from(body['user'] as JsonMap);
          userMap['role'] = 'coach';
          final rawCoach = body['coach'] ?? body['coach_profile'];
          if (rawCoach is JsonMap) {
            userMap['coach'] = rawCoach;
          }
          currentUser = AppUser.fromJson(userMap);
        }
        await _persistSession(authToken, currentUser);
        notifyListeners();

        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ??
              'Pendaftaran Pelatih berhasil! Menunggu verifikasi Admin.',
          user: currentUser,
          token: authToken,
        );
      }

      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(body, 'Pendaftaran Pelatih gagal.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message: 'Tidak dapat terhubung ke server Laravel.',
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
          final userMap = Map<String, dynamic>.from(body['user'] as JsonMap);
          final rawCoach = body['coach'] ?? body['coach_profile'];
          if (rawCoach is JsonMap) {
            userMap['coach'] = rawCoach;
          }
          currentUser = AppUser.fromJson(userMap);
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
  // 6. RIWAYAT OLAHRAGA, JADWAL, NOTIFIKASI, EDUKASI & BERAT BADAN PESERTA
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

  // =========================================================================
  // 7. PORTAL PELATIH (STATUS VERIFIKASI, DASHBOARD, PESERTA & REKOMENDASI)
  // =========================================================================
  Future<CoachProfile?> refreshCoachStatus() async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/coach/verification-status'),
              headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        final rawCoach =
            body['coach'] ?? body['coach_profile'] ?? body['data'];
        if (body['success'] == true &&
            rawCoach is JsonMap &&
            currentUser != null) {
          currentUser!.coach = CoachProfile.fromJson(rawCoach);
          currentUser!.name = currentUser!.coach!.nama;
          await _persistSession(authToken, currentUser);
          notifyListeners();
          return currentUser!.coach;
        }
      }
    } catch (_) {}
    return currentUser?.coach;
  }

  Future<JsonMap?> fetchCoachDashboard() async {
    if (!isLoggedIn) {
      debugPrint('[PELATIH_DASHBOARD] Token kosong / belum login');
      return null;
    }
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/coach/dashboard'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));
      debugPrint('[PELATIH_DASHBOARD] Status: ${response.statusCode}');
      debugPrint('[PELATIH_DASHBOARD] Body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is JsonMap) {
          return body['data'] as JsonMap;
        }
      }
    } catch (e) {
      debugPrint('[PELATIH_DASHBOARD] Exception: $e');
    }
    return null;
  }

  JsonMap _normalizeClientMap(dynamic raw, {String defaultStatus = 'active'}) {
    final map = Map<String, dynamic>.from(raw as Map);
    final status =
        (map['status_hubungan'] ?? map['status'] ?? defaultStatus).toString();
    final relId = (map['relasi_id'] ?? map['id'] ?? '').toString();
    final userId = (map['id_akun'] ?? map['user_id'] ?? '').toString();

    map['relasi_id'] = relId;
    map['id'] = relId;
    map['status_hubungan'] = status;
    map['status'] = status;
    map['id_akun'] = userId;
    map['user_id'] = userId;
    map['user'] = Map<String, dynamic>.from(map);
    return map;
  }

  Future<List<JsonMap>> fetchCoachClients() async {
    if (!isLoggedIn) {
      lastCoachClientsDebug = 'Token kosong / belum login';
      debugPrint('[PELATIH_PESERTA] $lastCoachClientsDebug');
      return [];
    }
    try {
      final url = '$baseUrl/coach/klien';
      final response = await http
          .get(Uri.parse(url), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));

      lastCoachClientsDebug =
          'URL: $url\nPelatih ID Login: ${currentUser?.coach?.id ?? '-'}\nHTTP ${response.statusCode}:\n${response.body}';
      debugPrint('[PELATIH_PESERTA] $lastCoachClientsDebug');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true) {
          final rawData = body['data'];
          if (rawData is JsonMap) {
            final pendingList = (rawData['pending'] as List? ?? [])
                .map((e) => _normalizeClientMap(e, defaultStatus: 'pending'))
                .toList();
            final aktifList = (rawData['aktif'] as List? ?? [])
                .map((e) => _normalizeClientMap(e, defaultStatus: 'active'))
                .toList();
            return [...pendingList, ...aktifList];
          }
          if (rawData is List) {
            return rawData.map((e) => _normalizeClientMap(e)).toList();
          }
        }
      }
    } catch (e) {
      lastCoachClientsDebug = 'Error koneksi: $e';
      debugPrint('[PELATIH_PESERTA] $lastCoachClientsDebug');
    }
    return [];
  }

  Future<AuthResult> respondCoachClient(String clientRelId, String aksi) async {
    final normalizedAksi =
        (aksi == 'approve' || aksi == 'terima' || aksi == 'active')
            ? 'approve'
            : 'reject';
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/coach/klien/$clientRelId/respond'),
            headers: _jsonHeaders,
            body: jsonEncode({'aksi': normalizedAksi}),
          )
          .timeout(const Duration(seconds: 12));
      final body = jsonDecode(response.body) as JsonMap;
      return AuthResult(
        isSuccess: response.statusCode == 200 && body['success'] == true,
        message: body['message']?.toString() ?? 'Status peserta diperbarui.',
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  Future<JsonMap?> fetchCoachClientDetail(String userId) async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/coach/klien/$userId'),
              headers: _jsonHeaders)
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

  Future<AuthResult> updateCoachProfile({
    required String nama,
    required String tempatLahir,
    required String tanggalLahir,
    required String noHp,
    String? spesialisasi,
    String? bio,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/coach/profile/update'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'nama': nama.trim(),
              'tempat_lahir': tempatLahir.trim(),
              'tanggal_lahir': tanggalLahir,
              'no_hp': noHp.trim(),
              'spesialisasi': spesialisasi?.trim(),
              'bio': bio?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;
      if (response.statusCode == 200 && body['success'] == true) {
        final rawCoach = body['coach'] ?? body['coach_profile'];
        if (rawCoach is JsonMap && currentUser != null) {
          currentUser!.coach = CoachProfile.fromJson(rawCoach);
          currentUser!.name = currentUser!.coach!.nama;
          await _persistSession(authToken, currentUser);
          notifyListeners();
        }
        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ?? 'Profil Pelatih diperbarui!',
        );
      }
      return AuthResult(
        isSuccess: false,
        message:
            _extractErrorMessage(body, 'Gagal memperbarui profil Pelatih.'),
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  Future<List<JsonMap>> fetchCoachNotifikasi() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/coach/notifikasi'), headers: _jsonHeaders)
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

  Future<void> markCoachNotifikasiRead() async {
    if (!isLoggedIn) return;
    try {
      await http
          .post(Uri.parse('$baseUrl/coach/notifikasi/baca'),
              headers: _jsonHeaders)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // --- CRUD Rekomendasi Olahraga (Pelatih) ---
  Future<List<JsonMap>> fetchCoachRekomendasiOlahraga({String? userId}) async {
    if (!isLoggedIn) return [];
    try {
      final uri = Uri.parse(
        userId != null
            ? '$baseUrl/coach/rekomendasi-olahraga?user_id=$userId'
            : '$baseUrl/coach/rekomendasi-olahraga',
      );
      final response = await http
          .get(uri, headers: _jsonHeaders)
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

  Future<AuthResult> saveCoachRekomendasiOlahraga({
    String? id,
    required JsonMap payload,
  }) async {
    try {
      final uri = id == null
          ? Uri.parse('$baseUrl/coach/rekomendasi-olahraga')
          : Uri.parse('$baseUrl/coach/rekomendasi-olahraga/$id');
      final response = await (id == null
              ? http.post(uri,
                  headers: _jsonHeaders, body: jsonEncode(payload))
              : http.put(uri,
                  headers: _jsonHeaders, body: jsonEncode(payload)))
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ??
              'Rekomendasi olahraga berhasil disimpan.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message: _extractErrorMessage(body, 'Gagal menyimpan rekomendasi.'),
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  Future<bool> deleteCoachRekomendasiOlahraga(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/coach/rekomendasi-olahraga/$id'),
              headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        return body['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  // --- CRUD Rekomendasi Makanan Diet (Pelatih) ---
  Future<List<JsonMap>> fetchCoachRekomendasiMakanan({String? userId}) async {
    if (!isLoggedIn) return [];
    try {
      final uri = Uri.parse(
        userId != null
            ? '$baseUrl/coach/rekomendasi-makanan?user_id=$userId'
            : '$baseUrl/coach/rekomendasi-makanan',
      );
      final response = await http
          .get(uri, headers: _jsonHeaders)
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

  Future<AuthResult> saveCoachRekomendasiMakanan({
    String? id,
    required JsonMap payload,
  }) async {
    try {
      final uri = id == null
          ? Uri.parse('$baseUrl/coach/rekomendasi-makanan')
          : Uri.parse('$baseUrl/coach/rekomendasi-makanan/$id');
      final response = await (id == null
              ? http.post(uri,
                  headers: _jsonHeaders, body: jsonEncode(payload))
              : http.put(uri,
                  headers: _jsonHeaders, body: jsonEncode(payload)))
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as JsonMap;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return AuthResult(
          isSuccess: true,
          message: body['message']?.toString() ??
              'Rekomendasi makanan diet berhasil disimpan.',
        );
      }
      return AuthResult(
        isSuccess: false,
        message:
            _extractErrorMessage(body, 'Gagal menyimpan rekomendasi makanan.'),
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  Future<bool> deleteCoachRekomendasiMakanan(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/coach/rekomendasi-makanan/$id'),
              headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        return body['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  // =========================================================================
  // 8. SISI PESERTA: PILIH PELATIH, KONFIRMASI JADWAL & REKOMENDASI DIET
  // =========================================================================
  Future<List<JsonMap>> fetchAvailableCoaches() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/coaches'), headers: _jsonHeaders)
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

  Future<JsonMap?> fetchMyCoach() async {
    if (!isLoggedIn) return null;
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/rekomendasi-coach'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is JsonMap) {
          final data = body['data'] as JsonMap;
          final coachAktif = data['coach_aktif'] ?? data['coach'];
          if (coachAktif is JsonMap) {
            return {
              ...coachAktif,
              'status': 'active',
              'coach': coachAktif,
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<AuthResult> pilihCoach(String coachId, {String? catatan}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/coaches/$coachId/request'),
            headers: _jsonHeaders,
            body: jsonEncode({
              if (catatan != null && catatan.trim().isNotEmpty)
                'catatan': catatan.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body) as JsonMap;
      return AuthResult(
        isSuccess: (response.statusCode == 200 || response.statusCode == 201) &&
            body['success'] == true,
        message: body['message']?.toString() ??
            'Permintaan pendampingan dikirim ke Pelatih.',
      );
    } catch (_) {
      return AuthResult(
          isSuccess: false, message: 'Gagal terhubung ke server.');
    }
  }

  Future<List<JsonMap>> fetchUserRekomendasiMakanan() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/rekomendasi-coach'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true) {
          if (body['data'] is JsonMap) {
            final data = body['data'] as JsonMap;
            if (data['rekomendasi_makanan'] is List) {
              return List<JsonMap>.from(data['rekomendasi_makanan'] as List);
            }
            if (data['makanan'] is List) {
              return List<JsonMap>.from(data['makanan'] as List);
            }
          }
          if (body['data'] is List) {
            return List<JsonMap>.from(body['data'] as List);
          }
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<JsonMap>> fetchUserRekomendasiOlahraga() async {
    if (!isLoggedIn) return [];
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/rekomendasi-coach'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as JsonMap;
        if (body['success'] == true && body['data'] is JsonMap) {
          final data = body['data'] as JsonMap;
          if (data['rekomendasi_olahraga'] is List) {
            return List<JsonMap>.from(data['rekomendasi_olahraga'] as List);
          }
          if (data['olahraga'] is List) {
            return List<JsonMap>.from(data['olahraga'] as List);
          }
        }
      }
    } catch (_) {}
    return [];
  }

  Future<AuthResult> respondRekomendasiOlahraga({
    required String rekomendasiId,
    required String aksi, // 'accepted' | 'rejected'
    String? catatan,
  }) async {
    final aksiServer = (aksi == 'accepted' || aksi == 'terima')
        ? 'terima'
        : 'tolak';
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/rekomendasi-olahraga/$rekomendasiId/respons'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'aksi': aksiServer,
              if (catatan != null && catatan.trim().isNotEmpty)
                'catatan_peserta': catatan.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body) as JsonMap;
      return AuthResult(
        isSuccess: response.statusCode == 200 && body['success'] == true,
        message: body['message']?.toString() ??
            (aksiServer == 'terima'
                ? 'Jadwal olahraga dari Pelatih berhasil diterima.'
                : 'Jadwal olahraga dari Pelatih ditolak.'),
      );
    } catch (_) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server Laravel.',
      );
    }
  }
}