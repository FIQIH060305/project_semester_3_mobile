import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/jadwal_item.dart';
import '../../models/riwayat_item.dart';
import '../../services/auth_service.dart';
import '../../services/jadwal_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gerak_animations.dart';
import '../../widgets/weekly_weight_card.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../profil/profil_screen.dart';
import '../main_navigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool showBottomNav;
  const DashboardScreen({super.key, this.showBottomNav = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _namaPengguna = AuthService.instance.currentUser?.name ?? 'Sobat GERAK';
  int _serverLangkahHariIni = 0;
  double _serverKaloriHariIni = 0;
  int _serverTotalSesiBulanIni = 0;

  List<JsonMap> _edukasiList = [];
  final GlobalKey<WeeklyWeightCardState> _weightCardKey =
      GlobalKey<WeeklyWeightCardState>();

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    JadwalService.instance.addListener(_onStateChanged);
    RiwayatService.instance.addListener(_onStateChanged);
    JadwalService.instance.initialize();
    RiwayatService.instance.initialize();
    _loadDashboardFromServer();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    JadwalService.instance.removeListener(_onStateChanged);
    RiwayatService.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        _namaPengguna = user.name;
      }
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  int get _effectiveLangkahHariIni {
    final lokalHariIni = RiwayatService.instance.aktivitasHariIni
        .fold<int>(0, (sum, e) => sum + e.langkah);
    return math.max(_serverLangkahHariIni, lokalHariIni);
  }

  double get _effectiveKaloriHariIni {
    final lokalKalori = RiwayatService.instance.aktivitasHariIni
        .fold<double>(0.0, (sum, e) => sum + e.kalori);
    return math.max(_serverKaloriHariIni, lokalKalori);
  }

  int get _effectiveSesiBulanIni {
    final now = DateTime.now();
    final lokalBulanIni = RiwayatService.instance.semuaRiwayat
        .where((e) => e.tanggal.year == now.year && e.tanggal.month == now.month)
        .length;
    return math.max(_serverTotalSesiBulanIni, lokalBulanIni);
  }

  Future<void> _loadDashboardFromServer({bool refreshWeightCard = false}) async {
    if (refreshWeightCard) {
      _weightCardKey.currentState?.loadWeeklyData();
    }
    await JadwalService.instance.syncFromServer();
    await RiwayatService.instance.syncFromServer();
    final data = await AuthService.instance.fetchDashboardData();
    final edukasi = await AuthService.instance.fetchEdukasiList();

    if (!mounted) return;

    setState(() {
      _edukasiList = edukasi;

      if (data != null) {
        final user = data['user'] as JsonMap?;
        final hariIni = data['hari_ini'] as JsonMap?;

        if (user != null) {
          _namaPengguna = user['nama_lengkap']?.toString() ?? _namaPengguna;
        }
        if (hariIni != null) {
          _serverLangkahHariIni =
              int.tryParse(hariIni['langkah']?.toString() ?? '') ?? 0;
          _serverKaloriHariIni =
              double.tryParse(hariIni['kalori']?.toString() ?? '') ?? 0;
        }
        _serverTotalSesiBulanIni =
            int.tryParse(data['total_sesi_bulan_ini']?.toString() ?? '') ?? 0;
      }
    });
  }

  String? _extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String _formatTanggalPublish(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    final dt = DateTime.tryParse(rawDate);
    if (dt == null) return rawDate;
    return DateFormat('d MMM yyyy', 'id_ID').format(dt);
  }

  Future<void> _bukaKontenEdukasi(JsonMap item) async {
    var urlStr = (item['url_video_youtube']?.toString() ?? '').trim();
    if (urlStr.isNotEmpty) {
      if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
        urlStr = 'https://$urlStr';
      }
      final uri = Uri.tryParse(urlStr);
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(22),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item['judul']?.toString() ?? 'Edukasi GERAK',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            if ((item['tanggal_publish']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Dipublikasikan: ${_formatTanggalPublish(item['tanggal_publish']?.toString())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              item['konten_teks']?.toString() ??
                  item['deskripsi']?.toString() ??
                  '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF1D5FC9),
          onRefresh: () => _loadDashboardFromServer(refreshWeightCard: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GerakEntrance(delayMs: 0, child: _buildHeader()),
                const SizedBox(height: 16),
                GerakEntrance(delayMs: 80, child: _buildFokusPagiCard()),
                const SizedBox(height: 18),
                GerakEntrance(delayMs: 160, child: _buildLatihanCard()),
                const SizedBox(height: 16),
                GerakEntrance(
                  delayMs: 240,
                  child: Row(
                    children: [
                      Expanded(child: _buildLangkahCard()),
                      const SizedBox(width: 14),
                      Expanded(child: _buildKaloriCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GerakEntrance(
                  delayMs: 320,
                  child: WeeklyWeightCard(
                    key: _weightCardKey,
                    onWeightUpdated: _loadDashboardFromServer,
                  ),
                ),
                if (_edukasiList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  GerakEntrance(delayMs: 380, child: _buildEdukasiSection()),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _buildHeader() {
    final photoPath = AuthService.instance.currentUser?.photoPath;
    final sesiBulanIni = _effectiveSesiBulanIni;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hai, $_namaPengguna',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Semangat jaga kesehatan!',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDF7D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '$sesiBulanIni Sesi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final nav = MainNavigationController.of(context);
                if (nav != null) {
                  nav.switchTab(4);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilScreen()),
                  );
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2F80ED), width: 2),
                ),
                child: ClipOval(
                  child: _buildHeaderAvatar(photoPath),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAvatar(String? photoPath) {
    if (photoPath != null && photoPath.isNotEmpty) {
      if (photoPath.startsWith('http')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackHeaderAvatar(),
        );
      }
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackHeaderAvatar(),
        );
      }
    }
    return _buildFallbackHeaderAvatar();
  }

  Widget _buildFallbackHeaderAvatar() {
    return Image.asset(
      'assets/images/profile_user.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFDBEAFE),
        child: const Icon(
          Icons.person_rounded,
          color: Color(0xFF2F80ED),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFokusPagiCard() {
    return GestureDetector(
      onTap: () {
        final nav = MainNavigationController.of(context);
        if (nav != null) nav.switchTab(2);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5697F8), Color(0xFF1D5FC9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D5FC9).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GerakPulseBeacon(
                      pulseColor: Colors.white,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FOKUS HARI INI • KETUK MULAI LARI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bersiap capai 5KM Pertamamu!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 2,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                  );
                },
                child: Icon(
                  Icons.notifications_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatihanCard() {
    final jadwalHariIni = JadwalService.instance.hariIni;
    final daftarTampil = jadwalHariIni.isNotEmpty
        ? jadwalHariIni
        : JadwalService.instance.semuaJadwal.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Transform.rotate(
                    angle: -0.5,
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFF00A3FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Latihan Hari ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  final nav = MainNavigationController.of(context);
                  if (nav != null) nav.switchTab(1);
                },
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0077E6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (daftarTampil.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada jadwal latihan hari ini. Ketuk "Lihat semua" untuk membuat jadwal.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
            )
          else
            ...List.generate(daftarTampil.length, (index) {
              final JadwalItem item = daftarTampil[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index < daftarTampil.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => JadwalService.instance.toggleSelesai(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: item.selesai
                          ? const Color(0xFFD6EEFF)
                          : const Color(0xFFF1F7FF),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: item.selesai
                                ? const Color(0xFF0084FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.selesai
                                  ? const Color(0xFF0084FF)
                                  : const Color(0xFF1F2937),
                              width: 1.6,
                            ),
                          ),
                          child: item.selesai
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.judul,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  decoration: item.selesai
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.kategoriWaktu,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: item.selesai
                                ? const Color(0xFF8DC8FF)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item.labelBadge,
                            style: const TextStyle(
                              color: Color(0xFF0F4882),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEdukasiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.play_circle_fill_rounded,
                color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Edukasi & Video Latihan',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _edukasiList.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = _edukasiList[index];
              final videoUrl = item['url_video_youtube']?.toString();
              final ytId = _extractYoutubeId(videoUrl);
              final customThumb = item['thumbnail']?.toString();
              final thumbUrl = (customThumb != null && customThumb.isNotEmpty)
                  ? customThumb
                  : (ytId != null
                      ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg'
                      : null);
              final isVideo =
                  ytId != null || (videoUrl != null && videoUrl.isNotEmpty);
              final tglPublish =
                  _formatTanggalPublish(item['tanggal_publish']?.toString());

              return GestureDetector(
                onTap: () => _bukaKontenEdukasi(item),
                child: Container(
                  width: 245,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(17)),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 118,
                              width: double.infinity,
                              color: const Color(0xFFDBEAFE),
                              child: thumbUrl != null
                                  ? Image.network(
                                      thumbUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.fitness_center_rounded,
                                        color: Color(0xFF1D5FC9),
                                        size: 36,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.menu_book_rounded,
                                      color: Color(0xFF1D5FC9),
                                      size: 36,
                                    ),
                            ),
                            if (isVideo)
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['kategori']?.toString().toUpperCase() ??
                                    'EDUKASI',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0077E6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['judul']?.toString() ?? 'Konten GERAK',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                              const Spacer(),
                              if (tglPublish.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tglPublish,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLangkahCard() {
    final langkah = _effectiveLangkahHariIni;
    final ratio = (langkah / 10000).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD7FCD7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8BF08B), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomPaint(
                size: const Size(22, 16),
                painter: _SneakerIconPainter(),
              ),
              const SizedBox(width: 6),
              const Text(
                'Langkah',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GerakAnimatedMetric(
            targetValue: langkah.toDouble(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          _buildPillProgressBar(ratio: ratio),
          const SizedBox(height: 6),
          const Text(
            'Target 10,000',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaloriCard() {
    final kalori = _effectiveKaloriHariIni;
    final ratio = (kalori / 600).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF9800),
                size: 22,
              ),
              SizedBox(width: 4),
              Text(
                'Kalori',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GerakAnimatedMetric(
            targetValue: kalori,
            suffix: ' kcal',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          _buildPillProgressBar(ratio: ratio),
          const SizedBox(height: 6),
          const Text(
            'Target 600 kcal',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillProgressBar({required double ratio}) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animatedRatio, _) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animatedRatio,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E60D0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SneakerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.25);
    path.lineTo(size.width * 0.35, size.height * 0.1);
    path.lineTo(size.width * 0.55, size.height * 0.45);
    path.lineTo(size.width * 0.9, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.85,
      size.width * 0.8,
      size.height * 0.85,
    );
    path.lineTo(size.width * 0.1, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.05,
      size.height * 0.55,
      size.width * 0.15,
      size.height * 0.25,
    );

    canvas.drawPath(path, paint);

    final lacePaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.35),
      Offset(size.width * 0.45, size.height * 0.42),
      lacePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.55, size.height * 0.58),
      lacePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.95),
      Offset(size.width * 0.85, size.height * 0.95),
      lacePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}