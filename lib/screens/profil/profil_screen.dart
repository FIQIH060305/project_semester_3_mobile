import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // 1. CARD AVATAR + NAMA + EDIT PROFIL
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildAvatarCard(BuildContext context) {
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
              Container(
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
                  child: Image.asset(
                    'assets/images/profile_user.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFDBEAFE),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF0077E6),
                        size: 54,
                      ),
                    ),
                  ),
                ),
              ),

              // Ikon kamera di pojok kanan bawah avatar
              Positioned(
                bottom: 0,
                right: 0,
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
            ],
          ),
          const SizedBox(height: 14),

          // Nama
          const Text(
            'Fiqih Al Firdaus',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // Lokasi
          const Text(
            'Jember,  Indonesia',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // Tombol Edit Profil
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Halaman Edit Profil akan segera hadir!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Icon(Icons.bolt_rounded,
                      color: Color(0xFFD97706), size: 18),
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
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
                Icon(Icons.emoji_events_outlined,
                    color: Color(0xFF0077E6), size: 20),
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
}
