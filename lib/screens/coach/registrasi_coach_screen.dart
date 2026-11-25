import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

class RegistrasiCoachScreen extends StatefulWidget {
  const RegistrasiCoachScreen({super.key});

  @override
  State<RegistrasiCoachScreen> createState() => _RegistrasiCoachScreenState();
}

class _RegistrasiCoachScreenState extends State<RegistrasiCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _noHpController = TextEditingController();
  final _spesialisasiController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _tanggalLahir;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _namaController.dispose();
    _tempatLahirController.dispose();
    _noHpController.dispose();
    _spesialisasiController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _hitungUsia(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pilihTanggalLahir() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1955, 1, 1),
      lastDate: DateTime(now.year - 17, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tanggalLahir = picked);
    }
  }

  Future<void> _submitCoach() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;

    if (_tanggalLahir == null) {
      _showSnack('Tanggal lahir wajib dipilih.', isError: true);
      return;
    }

    if (!_agreeToTerms) {
      _showSnack('Setujui ketentuan pendaftaran Coach terlebih dahulu.',
          isError: true);
      return;
    }

    if (!valid || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await AuthService.instance.registerCoach(
        nama: _namaController.text,
        tempatLahir: _tempatLahirController.text,
        tanggalLahir: _tanggalLahir!,
        noHp: _noHpController.text,
        email: _emailController.text,
        password: _passwordController.text,
        spesialisasi: _spesialisasiController.text,
        bio: _bioController.text,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        _showSnack(result.message, isError: true);
        return;
      }

      _showSnack(result.message, isError: false);
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/coach-verifikasi', (route) => false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFD84343) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tglLabel = _tanggalLahir == null
        ? 'Pilih tanggal lahir'
        : '${DateFormat('dd MMMM yyyy', 'id_ID').format(_tanggalLahir!)} (${_hitungUsia(_tanggalLahir!)} thn)';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pendaftaran Coach GERAK',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info Verifikasi Admin
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF005BAC), Color(0xFF0077E6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bergabung Sebagai Coach',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Data pendaftaran akan diverifikasi oleh Admin GERAK sebelum akun Coach aktif.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _label('Nama Lengkap Coach'),
                AppTextField(
                  controller: _namaController,
                  hintText: 'Masukkan nama lengkap & gelar (opsional)',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 14),

                _label('Tempat Lahir'),
                AppTextField(
                  controller: _tempatLahirController,
                  hintText: 'Contoh: Jember',
                  prefixIcon: Icons.location_city_rounded,
                  textInputAction: TextInputAction.next,
                  validator: Validators.requiredText('Tempat lahir'),
                ),
                const SizedBox(height: 14),

                _label('Tanggal Lahir'),
                InkWell(
                  onTap: _pilihTanggalLahir,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tglLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _tanggalLahir == null
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: _tanggalLahir == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.textSecondary, size: 19),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _label('Nomor Handphone (WhatsApp Aktif)'),
                AppTextField(
                  controller: _noHpController,
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phoneNumber,
                ),
                const SizedBox(height: 14),

                _label('Spesialisasi Latihan / Diet'),
                AppTextField(
                  controller: _spesialisasiController,
                  hintText: 'Contoh: Cardio, Fat Loss & Nutrisi Diet',
                  prefixIcon: Icons.fitness_center_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                _label('Pengalaman / Bio Singkat'),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Ceritakan pengalaman melatih atau sertifikasi yang kamu miliki...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _label('Alamat Email'),
                AppTextField(
                  controller: _emailController,
                  hintText: 'coach@gmail.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),

                _label('Kata Sandi'),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Minimal 8 karakter',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 14),

                _label('Konfirmasi Kata Sandi'),
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Ulangi kata sandi',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  validator: (val) =>
                      Validators.confirmPassword(_passwordController.text)(val),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _agreeToTerms = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'Saya menyatakan data identitas di atas benar dan bersedia diverifikasi oleh Admin GERAK.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCoach,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.3, color: Colors.white),
                          )
                        : const Text(
                            'Kirim Pendaftaran Coach',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}