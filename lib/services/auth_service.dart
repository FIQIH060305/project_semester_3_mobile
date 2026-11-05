import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Model pengguna untuk autentikasi
class AppUser {
  final String id;
  String name;
  final String email;
  String passwordHash;
  String salt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
  });
}

/// Model token / kode reset password
class PasswordResetToken {
  final String token;
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool isUsed;

  PasswordResetToken({
    required this.token,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;
}

/// Hasil dari operasi autentikasi
class AuthResult {
  final bool isSuccess;
  final String message;
  final AppUser? user;
  final String? resetToken;

  AuthResult({
    required this.isSuccess,
    required this.message,
    this.user,
    this.resetToken,
  });
}

/// Layanan Autentikasi dan Manajemen Password Reset
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Durasi masa berlaku token reset password (10 Menit)
  static const Duration tokenExpiryDuration = Duration(minutes: 10);

  // Database in-memory untuk user terdaftar
  final Map<String, AppUser> _usersByEmail = {};

  // Daftar token reset password yang pernah dibuat
  final List<PasswordResetToken> _resetTokens = [];

  // Pengguna yang sedang login saat ini
  AppUser? currentUser;

  // Inisialisasi data awal (Pre-seeded users)
  static void initialize() {
    final auth = instance;
    if (auth._usersByEmail.isEmpty) {
      auth.register(
        name: 'Fiqih Al Firdaus',
        email: 'fiqih@gerak.id',
        password: 'Password123!',
      );
      auth.register(
        name: 'Pengguna Gerak',
        email: 'user@gmail.com',
        password: 'Password123!',
      );
    }
  }

  /// Helper untuk hashing password dengan salt menggunakan SHA-256
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password::$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate salt acak
  static String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Generate 6 digit token / kode verifikasi reset password
  static String _generateResetToken() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  // =========================================================================
  // 1. REGISTRASI
  // =========================================================================
  AuthResult register({
    required String name,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();

    if (_usersByEmail.containsKey(normalizedEmail)) {
      return AuthResult(
        isSuccess: false,
        message: 'Alamat email sudah terdaftar. Silakan masuk.',
      );
    }

    final salt = _generateSalt();
    final passwordHash = hashPassword(password, salt);

    final newUser = AppUser(
      id: 'USR_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: passwordHash,
      salt: salt,
    );

    _usersByEmail[normalizedEmail] = newUser;
    currentUser = newUser;

    return AuthResult(
      isSuccess: true,
      message: 'Registrasi berhasil.',
      user: newUser,
    );
  }

  // =========================================================================
  // 2. LOGIN
  // =========================================================================
  AuthResult login({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _usersByEmail[normalizedEmail];

    if (user == null) {
      return AuthResult(
        isSuccess: false,
        message: 'Email atau kata sandi tidak sesuai.',
      );
    }

    final expectedHash = hashPassword(password, user.salt);
    if (expectedHash != user.passwordHash) {
      return AuthResult(
        isSuccess: false,
        message: 'Email atau kata sandi tidak sesuai.',
      );
    }

    currentUser = user;
    return AuthResult(
      isSuccess: true,
      message: 'Berhasil masuk.',
      user: user,
    );
  }

  // =========================================================================
  // 3. REQUEST LUPA PASSWORD
  // =========================================================================
  /// Memeriksa email dan membuat token reset jika email terdaftar.
  AuthResult requestPasswordReset(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _usersByEmail[normalizedEmail];

    // Jika email tidak terdaftar
    if (user == null) {
      return AuthResult(
        isSuccess: false,
        message: 'Alamat email tidak terdaftar dalam sistem.',
      );
    }

    // Nonaktifkan token lama milik email ini yang belum terpakai
    for (final t in _resetTokens.where((t) => t.email == normalizedEmail && !t.isUsed)) {
      t.isUsed = true;
    }

    // Buat token / kode reset baru dengan masa berlaku 10 menit
    final tokenCode = _generateResetToken();
    final now = DateTime.now();
    final resetToken = PasswordResetToken(
      token: tokenCode,
      email: normalizedEmail,
      createdAt: now,
      expiresAt: now.add(tokenExpiryDuration),
    );

    _resetTokens.add(resetToken);

    return AuthResult(
      isSuccess: true,
      message: 'Kode reset password berhasil dikirim ke email kamu.',
      resetToken: tokenCode,
      user: user,
    );
  }

  // =========================================================================
  // 4. VERIFIKASI TOKEN RESET PASSWORD
  // =========================================================================
  AuthResult verifyResetToken({
    required String email,
    required String token,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();

    // Cari token yang cocok
    final matchingTokens = _resetTokens
        .where((t) => t.email == normalizedEmail && t.token == cleanToken)
        .toList();

    if (matchingTokens.isEmpty) {
      return AuthResult(
        isSuccess: false,
        message: 'Kode verifikasi salah atau tidak valid.',
      );
    }

    final latestToken = matchingTokens.last;

    if (latestToken.isUsed) {
      return AuthResult(
        isSuccess: false,
        message: 'Kode verifikasi ini sudah pernah digunakan.',
      );
    }

    if (latestToken.isExpired) {
      return AuthResult(
        isSuccess: false,
        message: 'Kode verifikasi telah kedaluwarsa. Silakan minta kode baru.',
      );
    }

    return AuthResult(
      isSuccess: true,
      message: 'Kode verifikasi valid.',
      resetToken: cleanToken,
    );
  }

  // =========================================================================
  // 5. RESET / SIMPAN PASSWORD BARU
  // =========================================================================
  AuthResult resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    // 1. Verifikasi kembali token
    final tokenCheck = verifyResetToken(email: email, token: token);
    if (!tokenCheck.isSuccess) {
      return tokenCheck;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final user = _usersByEmail[normalizedEmail];
    if (user == null) {
      return AuthResult(
        isSuccess: false,
        message: 'Akun pengguna tidak ditemukan.',
      );
    }

    // 2. Hash password baru dengan salt baru
    final newSalt = _generateSalt();
    final newHash = hashPassword(newPassword, newSalt);

    user.passwordHash = newHash;
    user.salt = newSalt;

    // 3. Tandai token sudah digunakan (hanya bisa 1x pakai)
    final usedToken = _resetTokens.lastWhere(
      (t) => t.email == normalizedEmail && t.token == token.trim(),
    );
    usedToken.isUsed = true;

    return AuthResult(
      isSuccess: true,
      message: 'Kata sandi berhasil diatur ulang! Silakan masuk dengan kata sandi baru.',
      user: user,
    );
  }

  /// Helper untuk mengecek apakah email terdaftar
  bool isEmailRegistered(String email) {
    return _usersByEmail.containsKey(email.trim().toLowerCase());
  }

  /// Ambil token aktif terakhir untuk keperluan pengujian / demo
  PasswordResetToken? getActiveToken(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      return _resetTokens.lastWhere((t) => t.email == normalizedEmail && t.isValid);
    } catch (_) {
      return null;
    }
  }

  /// Buat token sengaja kedaluwarsa (untuk pengujian skenario token expired)
  void makeTokenExpiredForTesting(String email, String token) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final t in _resetTokens.where((t) => t.email == normalizedEmail && t.token == token)) {
      // Ubah expiresAt ke masa lalu
      _resetTokens[_resetTokens.indexOf(t)] = PasswordResetToken(
        token: t.token,
        email: t.email,
        createdAt: t.createdAt.subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isUsed: t.isUsed,
      );
    }
  }
}

