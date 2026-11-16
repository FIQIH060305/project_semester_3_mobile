import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'edit_profil_screen.dart';

class ProfilScreen extends StatefulWidget {
  final bool showBottomNav;
  const ProfilScreen({super.key, this.showBottomNav = true});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ImagePicker _picker = ImagePicker();
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────
  // 1. LOGIKA LOGOUT
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _konfirmasiLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Hapus sesi autentikasi
      _authService.logout();

      if (!mounted) return;

      // 2. Tampilkan notifikasi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Anda telah berhasil keluar.')),
            ],
          ),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // 3. Arahkan kembali ke halaman Login dan hapus seluruh riwayat navigasi
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // 2. LOGIKA PILIH FOTO DARI KAMERA / GALERI
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _pilihSumberFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final hasCustomPhoto = _authService.currentUser?.photoPath != null &&
            _authService.currentUser!.photoPath!.isNotEmpty;

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
                  'Ganti Foto Profil',
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
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0077E6)),
                  ),
                  title: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
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
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0077E6)),
                  ),
                  title: const Text(
                    'Ambil Foto dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _ambilGambar(ImageSource.camera);
                  },
                ),
                if (hasCustomPhoto)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE1E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                    ),
                    title: const Text(
                      'Kembalikan Foto Bawaan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _authService.updateProfile(photoPath: '');
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
        _authService.updateProfile(photoPath: pickedFile.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Foto profil berhasil diperbarui!')),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: const Color(0xFFD84343),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // 3. NAVIGASI EDIT PROFIL
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _bukaEditProfil() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfilScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF38BDF8),
              size: 26,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _konfirmasiLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            tooltip: 'Keluar Akun',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              // ── 1. CARD AVATAR & NAMA ─────────────────────────────────
              _buildAvatarCard(context),
              const SizedBox(height: 18),

              // ── 2. STATISTIK 3 CARD TERPISAH ─────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildSingleStatCard(
                      icon: Icons.calendar_view_week_rounded,
                      nilai: '248.5',
                      label: 'TOTAL JARAK',
                      sublabel: 'Kilometer',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSingleStatCard(
                      icon: Icons.access_time_rounded,
                      nilai: '28j 45m',
                      label: 'DURASI',
                      sublabel: 'Bulan Ini',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSingleStatCard(
                      icon: Icons.speed_rounded,
                      nilai: "5'24\"",
                      label: 'RATA-RATA',
                      sublabel: 'Per Km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 3. CARD TARGET LARI MINGGUAN ──────────────────────────
              _buildTargetCard(),
              const SizedBox(height: 18),

              // ── 4. CARD TOMBOL LOGOUT TERINTEGRASI ─────────────────────
              _buildLogoutCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? const AppBottomNavBar(currentIndex: 4) : null,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // 1. CARD AVATAR + NAMA + EDIT PROFIL
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildAvatarCard(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Fiqih Al Firdaus';
    final displayLocation = user?.location.isNotEmpty == true ? user!.location : 'Jember,  Indonesia';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar dengan lingkaran biru dan ikon kamera
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _pilihSumberFoto,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0077E6),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(user?.photoPath),
                  ),
                ),
              ),

              // Ikon kamera di pojok kanan bawah avatar
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pilihSumberFoto,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0077E6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nama
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Lokasi
          Text(
            displayLocation,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Tombol Edit Profil
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _bukaEditProfil,
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Edit Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAC),
                elevation: 2,
                shadowColor: const Color(0xFF005BAC).withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
        );
      }
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return Image.asset(
      'assets/images/profile_user.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFDBEAFE),
        child: const Icon(
          Icons.person_rounded,
          color: Color(0xFF0077E6),
          size: 54,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // 2. STAT KARTU TUNGGAL
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildSingleStatCard({
    required IconData icon,
    required String nilai,
    required String label,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F1FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0077E6), size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            nilai,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0077E6),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // 3. CARD TARGET LARI MINGGUAN
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildTargetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row header: Flag icon + Title/Subtitle + 85% badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFED7AA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF78350F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Target Lari Mingguan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sisa 3 hari lagi di minggu ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '85%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row: 38.5 / 45 km  &  ⚡ Tinggal 6.5 km lagi!
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  children: [
                    TextSpan(text: '38.5'),
                    TextSpan(
                      text: ' / 45 km',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 2),
                  Text(
                    'Tinggal 6.5 km lagi!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.855,
              minHeight: 9,
              backgroundColor: Color(0xFFE8F1FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 16),

          // Streak banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.emoji_events_outlined, color: Color(0xFF0077E6), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Streak lari 4 minggu berturut-turut!',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Text(
                  'Hebat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0077E6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // 4. TOMBOL LOGOUT TERINTEGRASI DI HALAMAN
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _konfirmasiLogout,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Akhiri sesi aplikasi dan kembali ke login',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
