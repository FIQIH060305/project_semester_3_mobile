import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';

class EditProfilScreen extends StatefulWidget {
  final double initialBerat;
  final double initialTarget;

  const EditProfilScreen({
    super.key,
    this.initialBerat = 72.0,
    this.initialTarget = 65.0,
  });

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _tinggiController;
  late final TextEditingController _beratController;
  late final TextEditingController _targetController;
  final ImagePicker _picker = ImagePicker();

  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _namaController = TextEditingController(text: user?.name ?? 'Sobat GERAK');
    _tinggiController = TextEditingController(
      text: (user?.tinggiBadan ?? 170).toStringAsFixed(0),
    );
    _beratController = TextEditingController(
      text: (user?.beratBadan ?? widget.initialBerat).toStringAsFixed(1),
    );
    _targetController = TextEditingController(
      text: widget.initialTarget.toStringAsFixed(0),
    );
    _selectedImagePath = user?.photoPath;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _tinggiController.dispose();
    _beratController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pilihSumberFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF0077E6)),
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _ambilGambar(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF0077E6)),
                  ),
                  title: const Text(
                    'Ambil Foto dari Kamera',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _ambilGambar(ImageSource.camera);
                  },
                ),
                if (_selectedImagePath != null &&
                    _selectedImagePath!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE1E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444)),
                    ),
                    title: const Text(
                      'Hapus Foto Kustom',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() => _selectedImagePath = '');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _ambilGambar(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _selectedImagePath = pickedFile.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengakses galeri/kamera: $e'),
          backgroundColor: const Color(0xFFD84343),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _simpanProfil() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSaving) return;

    final nama = _namaController.text.trim();
    final tinggi = double.tryParse(_tinggiController.text.trim()) ?? 170;
    final berat = double.tryParse(_beratController.text.trim()) ?? 70;
    final target = double.tryParse(_targetController.text.trim()) ?? 65;

    if (target >= berat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Target berat badan harus lebih kecil dari berat badan saat ini.'),
          backgroundColor: Color(0xFFD84343),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await AuthService.instance.syncProfileUpdateToServer(
        namaLengkap: nama,
        tinggiBadan: tinggi,
        beratBadan: berat,
        beratTarget: target,
        photoPath: _selectedImagePath,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFFD84343),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF38BDF8),
              size: 24,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profil & Target',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pilihSumberFoto,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0077E6),
                                  width: 3.5,
                                ),
                              ),
                              child: ClipOval(child: _buildAvatarImage()),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0077E6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ketuk foto untuk mengganti avatar',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Nama Lengkap'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _namaController,
                        decoration: _inputDecoration(
                          icon: Icons.person_outline_rounded,
                          hint: 'Nama lengkap kamu',
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Nama minimal 2 karakter'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tinggi (cm)'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _tinggiController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    icon: Icons.height_rounded,
                                    hint: '170',
                                  ),
                                  validator: (v) {
                                    final n = double.tryParse(v ?? '');
                                    if (n == null || n < 140 || n > 200) {
                                      return '140-200 cm';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Berat (kg)'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _beratController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _inputDecoration(
                                    icon: Icons.monitor_weight_outlined,
                                    hint: '70',
                                  ),
                                  validator: (v) {
                                    final n = double.tryParse(v ?? '');
                                    if (n == null || n < 30 || n > 250) {
                                      return '30-250 kg';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Target Berat Badan (kg)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: _inputDecoration(
                          icon: Icons.flag_outlined,
                          hint: '65',
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 30 || n > 250) {
                            return 'Target berat tidak valid';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _simpanProfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005BAC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required IconData icon, required String hint}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF0077E6), size: 20),
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0077E6), width: 1.6),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) {
      if (_selectedImagePath!.startsWith('http')) {
        return Image.network(
          _selectedImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      }
      final file = File(_selectedImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        );
      }
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/profile_user.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFDBEAFE),
        child: const Icon(
          Icons.person_rounded,
          color: Color(0xFF0077E6),
          size: 54,
        ),
      ),
    );
  }
}