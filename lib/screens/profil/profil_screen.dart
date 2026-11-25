import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gerak_animations.dart';
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

  double _totalJarakKm = 0.0;
  int _totalSesi = 0;
  double _totalKalori = 0.0;
  double _beratAwal = 75.0;
  double _beratSekarang = 72.0;
  double _beratTarget = 65.0;
  int _progresPersen = 0;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;
    _authService.addListener(_onAuthChanged);
    _loadProfilStats();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfilStats() async {
    final dash = await _authService.fetchDashboardData();
    final riwayat = await _authService.fetchRiwayatOlahraga();

    if (!mounted) return;

    double jarak = 0;
    double kalori = 0;
    for (final item in riwayat) {
      jarak += double.tryParse(item['jarak_km']?.toString() ?? '0') ?? 0;
      kalori += double.tryParse(item['kalori_terbakar']?.toString() ?? '0') ?? 0;
    }

    setState(() {
      _totalJarakKm = jarak;
      _totalSesi = riwayat.length;
      _totalKalori = kalori;

      if (dash != null) {
        final user = dash['user'] as Map<String, dynamic>?;
        final target = dash['target'] as Map<String, dynamic>?;

        if (user != null) {
          _beratSekarang =
              double.tryParse(user['berat_sekarang']?.toString() ?? '') ??
                  _beratSekarang;
        }
        if (target != null) {
          _beratAwal =
              double.tryParse(target['berat_awal']?.toString() ?? '') ??
                  _beratAwal;
          _beratTarget =
              double.tryParse(target['berat_target']?.toString() ?? '') ??
                  _beratTarget;
          _progresPersen =
              int.tryParse(target['progres_persen']?.toString() ?? '') ?? 0;
        }
      }
    });
  }

  Future<void> _konfirmasiLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
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
      await _authService.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Anda telah berhasil keluar.')),
            ],
          ),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

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
                if (hasCustomPhoto)
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
                      'Kembalikan Foto Bawaan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      setState(() => _isUploadingPhoto = true);
                      final user = _authService.currentUser;
                      await _authService.syncProfileUpdateToServer(
                        namaLengkap: user?.name ?? 'Sobat GERAK',
                        tinggiBadan: user?.tinggiBadan ?? 170,
                        beratBadan: _beratSekarang,
                        beratTarget: _beratTarget,
                        photoPath: '',
                      );
                      if (mounted) setState(() => _isUploadingPhoto = false);
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
        setState(() => _isUploadingPhoto = true);
        final user = _authService.currentUser;

        final result = await _authService.syncProfileUpdateToServer(
          namaLengkap: user?.name ?? 'Sobat GERAK',
          tinggiBadan: user?.tinggiBadan ?? 170,
          beratBadan: _beratSekarang,
          beratTarget: _beratTarget,
          photoPath: pickedFile.path,
        );

        if (!mounted) return;
        setState(() => _isUploadingPhoto = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(result.message)),
              ],
            ),
            backgroundColor: result.isSuccess
                ? const Color(0xFF16A34A)
                : const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah foto: $e'),
          backgroundColor: const Color(0xFFD84343),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _bukaEditProfil() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfilScreen(
          initialBerat: _beratSekarang,
          initialTarget: _beratTarget,
        ),
      ),
    );
    if (updated == true) {
      _loadProfilStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
        child: RefreshIndicator(
          onRefresh: _loadProfilStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                GerakEntrance(delayMs: 0, child: _buildAvatarCard(context)),
                const SizedBox(height: 18),
                GerakEntrance(
                  delayMs: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSingleStatCard(
                          icon: Icons.route_rounded,
                          nilai: _totalJarakKm.toStringAsFixed(1),
                          label: 'TOTAL JARAK',
                          sublabel: 'Kilometer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSingleStatCard(
                          icon: Icons.directions_run_rounded,
                          nilai: '$_totalSesi',
                          label: 'AKTIVITAS',
                          sublabel: 'Total Sesi',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSingleStatCard(
                          icon: Icons.local_fire_department_rounded,
                          nilai: _totalKalori.toStringAsFixed(0),
                          label: 'TERBAKAR',
                          sublabel: 'Kcal',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GerakEntrance(delayMs: 200, child: _buildTargetCard()),
                const SizedBox(height: 18),
                GerakEntrance(delayMs: 280, child: _buildLogoutCard()),
                const SizedBox(height: 20),
                const SizedBox(height: 18),
                GerakEntrance(
                  delayMs: 240,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFDBEAFE), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pendampingan Coach & Diet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sports_rounded,
                                color: Color(0xFF0066CC)),
                          ),
                          title: const Text('Coach Pendamping Saya',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: const Text(
                              'Pilih pelatih & pantau program latihan',
                              style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Navigator.of(context).pushNamed('/user-coach'),
                        ),
                        const Divider(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.restaurant_menu_rounded,
                                color: Color(0xFF16A34A)),
                          ),
                          title: const Text('Rekomendasi Makanan Diet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: const Text(
                              'Menu nutrisi harian dari Coach kamu',
                              style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              Navigator.of(context).pushNamed('/user-diet'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNavBar(currentIndex: 4) : null,
    );
  }

  Widget _buildAvatarCard(BuildContext context) {
    final user = _authService.currentUser;
    final displayName =
        user?.name.isNotEmpty == true ? user!.name : 'Sobat GERAK';
    final displayEmail =
        user?.email.isNotEmpty == true ? user!.email : 'Jember, Indonesia';

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pilihSumberFoto,
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
                    child: _isUploadingPhoto
                        ? const Center(child: CircularProgressIndicator())
                        : _buildAvatarImage(user?.photoPath),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pilihSumberFoto,
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
          Text(
            displayEmail,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _bukaEditProfil,
              icon:
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Edit Profil & Target Berat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
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
      if (photoPath.startsWith('http')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackAvatar(),
        );
      }
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackAvatar(),
        );
      }
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
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

  Widget _buildTargetCard() {
    final sisaKg = (_beratSekarang - _beratTarget).clamp(0.0, 200.0);
    final ratio = (_progresPersen / 100.0).clamp(0.0, 1.0);

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Penurunan Berat Badan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sinkron dengan profil web GERAK',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_progresPersen%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  children: [
                    TextSpan(text: '${_beratSekarang.toStringAsFixed(1)} kg'),
                    TextSpan(
                      text: ' → ${_beratTarget.toStringAsFixed(0)} kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 2),
                  Text(
                    'Sisa ${sisaKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: const Color(0xFFE8F1FF),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: Color(0xFF0077E6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berat awal program: ${_beratAwal.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const Text(
                  'Aktif',
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