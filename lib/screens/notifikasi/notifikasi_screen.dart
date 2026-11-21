import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  bool _isLoading = true;
  List<JsonMap> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  Future<void> _loadNotifikasi() async {
    setState(() => _isLoading = true);
    final data = await AuthService.instance.fetchNotifikasiList();
    if (!mounted) return;
    setState(() {
      _items = data;
      _isLoading = false;
    });
    AuthService.instance.markNotifikasiReadOnServer();
  }

  String _formatJam(String? iso) {
    if (iso == null || iso.isEmpty) return 'Baru saja';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return 'Baru saja';
    return DateFormat('HH.mm').format(dt);
  }

  String _formatTanggalHeader(String? iso) {
    if (iso == null || iso.isEmpty) return 'Terbaru';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return 'Terbaru';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat('EEEE, d MMMM y', 'id_ID').format(dt);
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
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifikasi,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada notifikasi baru',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pengingat jadwal latihan & progresmu akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final waktuIso = item['waktu_kirim']?.toString();
                      final prevIso = index > 0
                          ? _items[index - 1]['waktu_kirim']?.toString()
                          : null;

                      final labelHari = _formatTanggalHeader(waktuIso);
                      final showHeader = index == 0 ||
                          labelHari != _formatTanggalHeader(prevIso);

                      final sudahDibaca = item['status_dibaca'] == true;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader) ...[
                            if (index > 0) const SizedBox(height: 14),
                            _buildSectionHeader(
                              tanggalLabel: labelHari,
                              tanggalSub: waktuIso != null
                                  ? DateFormat('d MMMM y', 'id_ID').format(
                                      DateTime.tryParse(waktuIso)?.toLocal() ??
                                          DateTime.now())
                                  : '',
                            ),
                            const SizedBox(height: 12),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildNotifCard(
                              stripeColor: sudahDibaca
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF2563EB),
                              iconContainerBg: const Color(0xFFBFDBFE),
                              icon: Icons.event_available_rounded,
                              iconColor: const Color(0xFF2563EB),
                              badgeLabel: sudahDibaca ? 'Dibaca' : 'Baru',
                              badgeBg: sudahDibaca
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFDBEAFE),
                              badgeTextColor: sudahDibaca
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF2563EB),
                              time: _formatJam(waktuIso),
                              title: item['judul']?.toString() ??
                                  'Pengingat Latihan GERAK',
                              desc1: item['pesan']?.toString() ?? '',
                              desc2: 'Tetap konsisten capai targetmu!',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String tanggalLabel,
    required String tanggalSub,
  }) {
    return Row(
      children: [
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
            if (tanggalSub.isNotEmpty) ...[
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
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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