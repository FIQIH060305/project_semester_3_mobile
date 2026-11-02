import 'package:flutter/material.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

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
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // ── HARI INI ─────────────────────────────────────────────────
          _buildSectionHeader(
            tanggalLabel: 'Hari ini',
            tanggalSub: 'Selasa, 20 Oktober 2026',
          ),
          const SizedBox(height: 12),

          // 1. Aktifitas
          _buildNotifCard(
            stripeColor: const Color(0xFF3B82F6),
            iconContainerBg: const Color(0xFFBFDBFE),
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF2563EB),
            badgeLabel: 'Aktifitas',
            badgeBg: const Color(0xFFDBEAFE),
            badgeTextColor: const Color(0xFF2563EB),
            time: '07.00',
            title: 'Jalan 20 menit',
            desc1: 'Kamu sudah menyelesaikan aktifitas hari ini.',
            desc2: 'Luar biasa tetap semangat!!!',
          ),
          const SizedBox(height: 12),

          // 2. Makanan
          _buildNotifCard(
            stripeColor: const Color(0xFF10B981),
            iconContainerBg: const Color(0xFFA7F3D0),
            icon: Icons.rice_bowl_rounded,
            iconColor: const Color(0xFF059669),
            badgeLabel: 'Makanan',
            badgeBg: const Color(0xFFD1FAE5),
            badgeTextColor: const Color(0xFF059669),
            time: '07.30',
            title: 'Cek Berat Badan Kamu',
            desc1: 'Sudah 3 hari belum diperbarui',
            desc2: 'Yuk, Catat berat badanmu sekarang!',
          ),
          const SizedBox(height: 12),

          // 3. Progres
          _buildNotifCard(
            stripeColor: const Color(0xFFA855F7),
            iconContainerBg: const Color(0xFFF3E8FF),
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF9333EA),
            badgeLabel: 'Progres',
            badgeBg: const Color(0xFFF3E8FF),
            badgeTextColor: const Color(0xFF9333EA),
            time: '08.00',
            title: 'Berat badan turun 1,5 Kg',
            desc1: 'Proses minggu ini bagus tetap pertahankan',
            desc2: 'Luar biasa tetap semangat!!!',
          ),
          const SizedBox(height: 24),

          // ── KEMARIN ──────────────────────────────────────────────────
          _buildSectionHeader(
            tanggalLabel: 'Kemarin',
            tanggalSub: 'Senin, 19 Oktober 2026',
          ),
          const SizedBox(height: 12),

          // 4. Kalori
          _buildNotifCard(
            stripeColor: const Color(0xFFF97316),
            iconContainerBg: const Color(0xFFFED7AA),
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFEA580C),
            badgeLabel: 'Kalori',
            badgeBg: const Color(0xFFFFEDD5),
            badgeTextColor: const Color(0xFFEA580C),
            time: '08.00',
            title: 'Kamu Membakar 320 Kalori',
            desc1: 'Hebat pembakaran kalori minggu ini',
            desc2: 'sudah cukup tinggi',
          ),
          const SizedBox(height: 12),

          // 5. Jadwal
          _buildNotifCard(
            stripeColor: const Color(0xFF3B82F6),
            iconContainerBg: const Color(0xFFBFDBFE),
            icon: Icons.equalizer_rounded,
            iconColor: const Color(0xFF2563EB),
            badgeLabel: 'Jadwal',
            badgeBg: const Color(0xFFDBEAFE),
            badgeTextColor: const Color(0xFF2563EB),
            time: '08.00',
            title: 'Admin membagikan jadwal\nberjalan 30 menit',
            desc1: 'Luar biasa tetap semangat!!!',
            desc2: null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String tanggalLabel,
    required String tanggalSub,
  }) {
    return Row(
      children: [
        // Kalender dengan jam di pojok
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFDCEAFE),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Icon(
                    Icons.access_time_filled,
                    color: Color(0xFF2563EB),
                    size: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tanggalLabel,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tanggalSub,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotifCard({
    required Color stripeColor,
    required Color iconContainerBg,
    required IconData icon,
    required Color iconColor,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeTextColor,
    required String time,
    required String title,
    required String desc1,
    String? desc2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF), // Soft light blue tint card
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored stripe
            Container(
              width: 12,
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconContainerBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge + Time row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    color: badgeTextColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Description
                          Text(
                            desc1,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          if (desc2 != null)
                            Text(
                              desc2,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
