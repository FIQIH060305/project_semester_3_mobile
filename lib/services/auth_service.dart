
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================
// MODEL USER
// =====================================================

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? jenisKelamin;
  final int? usia;
  final double? tinggiBadan;
  final double? beratBadanAwal;
  final String? fotoProfil;
  final String? statusAkun;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.jenisKelamin,
    this.usia,
    this.tinggiBadan,
    this.beratBadanAwal,
    this.fotoProfil,
    this.statusAkun,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id_akun']?.toString() ?? '',
      name: json['nama_lengkap'] ?? '',
      email: json['email'] ?? '',
      jenisKelamin: json['jenis_kelamin'],
      usia: int.tryParse(json['usia']?.toString() ?? ''),
      tinggiBadan:
          double.tryParse(json['tinggi_badan']?.toString() ?? ''),
      beratBadanAwal:
          double.tryParse(json['berat_badan_awal']?.toString() ?? ''),
      fotoProfil: json['foto_profil'],
      statusAkun: json['status_akun'],
    );
  }
}

// =====================================================
// AUTH RESULT
// =====================================================

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

// =====================================================
// AUTH SERVICE
// =====================================================

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const String _tokenKey = 'auth_token';

  AppUser? currentUser;
  String? _token;

  // Data registrasi sementara
  Map<String, dynamic>? _registrationDraft;

  // ===================================================
  // HEADER
  // ===================================================

  Future<Map<String, String>> _headers({
    bool authenticated = false,
  }) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ===================================================
  // TOKEN MANAGEMENT
  // ===================================================

  Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    return _token;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    _token = token;
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);

    _token = null;
    currentUser = null;
  }

  // ===================================================
  // RESPONSE HANDLING
  // ===================================================

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const FormatException('Format respons server tidak valid.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  String _errorMessage(http.Response response) {
    try {
      final body = _decodeResponse(response);

      if (body['errors'] is Map) {
        final errors = body['errors'] as Map;
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            messages.add(value.first.toString());
          }
        }

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      return body['message']?.toString() ??
          'Terjadi kesalahan pada server.';
    } catch (_) {
      return 'Terjadi kesalahan pada server.';
    }
  }

  // ===================================================
  // 1. REGISTER DRAFT
  // ===================================================

  AuthResult register({
    required String name,
    required String email,
    required String password,
  }) {
    _registrationDraft = {
      'nama_lengkap': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': password,
    };

    return AuthResult(
      isSuccess: true,
      message: 'Data registrasi berhasil disiapkan.',
    );
  }

  // ===================================================
  // 2. COMPLETE REGISTRATION
  // ===================================================


Future<AuthResult> completeRegistration({
  required String jenisKelamin,
  required int usia,
  required num tinggiBadan,
  required num beratBadanAwal,
  required String deviceName,
}) async {
  try {
    if (_registrationDraft == null) {
      return AuthResult(
        isSuccess: false,
        message: 'Data registrasi tidak ditemukan. Silakan daftar ulang.',
      );
    }

    final payload = {
      ..._registrationDraft!,
      'jenis_kelamin': jenisKelamin,
      'usia': usia,
      'tinggi_badan': tinggiBadan.toDouble(),
      'berat_badan_awal': beratBadanAwal.toDouble(),
      'device_name': deviceName,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    final body = _decodeResponse(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = body['data'];

      if (data is! Map || data['akun'] is! Map) {
        throw const FormatException('Data akun dari server tidak valid.');
      }

      final token = data['token']?.toString();

      if (token == null || token.isEmpty) {
        throw const FormatException('Token registrasi tidak ditemukan.');
      }

      final akun = Map<String, dynamic>.from(data['akun']);

      currentUser = AppUser.fromJson(akun);
      await _saveToken(token);

      _registrationDraft = null;

      return AuthResult(
        isSuccess: true,
        message: body['message'] ?? 'Registrasi berhasil!',
        user: currentUser,
        token: token,
      );
    }

    return AuthResult(
      isSuccess: false,
      message: _errorMessage(response),
    );
  } catch (e) {
    return AuthResult(
      isSuccess: false,
      message: 'Gagal menghubungi server: $e',
    );
  }
}

  // ===================================================
  // 3. LOGIN
  // ===================================================

  Future<AuthResult> login({
    required String email,
    required String password,
    String deviceName = 'GERAK Flutter',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await _headers(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'device_name': deviceName,
        }),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        final data = body['data'];

        final token = data['token']?.toString();

        if (token == null || token.isEmpty) {
          return AuthResult(
            isSuccess: false,
            message: 'Token login tidak ditemukan.',
          );
        }

        await _saveToken(token);

        currentUser = AppUser.fromJson(
          Map<String, dynamic>.from(data['akun']),
        );

        return AuthResult(
          isSuccess: true,
          message: body['message'] ?? 'Login berhasil!',
          user: currentUser,
          token: token,
        );
      }

      return AuthResult(
        isSuccess: false,
        message: _errorMessage(response),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal menghubungi server: $e',
      );
    }
  }

  // ===================================================
  // 4. GET PROFILE / ME
  // ===================================================

  Future<AuthResult> me() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: await _headers(authenticated: true),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        final akun = body['data']['akun'];

        currentUser = AppUser.fromJson(
          Map<String, dynamic>.from(akun),
        );

        return AuthResult(
          isSuccess: true,
          message: body['message'] ?? 'Profil berhasil diambil!',
          user: currentUser,
        );
      }

      if (response.statusCode == 401) {
        await _clearToken();
      }

      return AuthResult(
        isSuccess: false,
        message: _errorMessage(response),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal mengambil profil: $e',
      );
    }
  }

  // ===================================================
  // 5. LOGOUT
  // ===================================================

  Future<AuthResult> logout() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        await _clearToken();

        return AuthResult(
          isSuccess: true,
          message: 'Kamu sudah logout.',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _headers(authenticated: true),
      );

      final body = _decodeResponse(response);

      if (response.statusCode == 200) {
        await _clearToken();

        return AuthResult(
          isSuccess: true,
          message: body['message'] ?? 'Logout berhasil!',
        );
      }

      if (response.statusCode == 401) {
        await _clearToken();
      }

      return AuthResult(
        isSuccess: false,
        message: _errorMessage(response),
      );
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'Gagal logout: $e',
      );
    }
  }
}
