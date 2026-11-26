import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class CoachClientDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const CoachClientDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<CoachClientDetailScreen> createState() =>
      _CoachClientDetailScreenState();
}

class _CoachClientDetailScreenState extends State<CoachClientDetailScreen> {
  JsonMap? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final res = await AuthService.instance.fetchCoachClientDetail(widget.userId);
    if (!mounted) return;
    setState(() {
      _detail = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profil = _detail?['profil'] as JsonMap? ??
        _detail?['user'] as JsonMap? ??
        {};
    final target = _detail?['target'] as JsonMap? ?? {};
    final aktivitas = (_detail?['riwayat_olahraga'] as List?) ?? [];
    final beratHistory = (_detail?['riwayat_berat'] as List?) ?? [];

    final beratAwal = profil['berat_awal'] ??
        target['berat_awal'] ??
        profil['berat_badan_awal'] ??
        '-';
    final beratSekarang = profil['berat_sekarang'] ?? '-';
    final beratTarget = profil['berat_target'] ?? target['berat_target'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profil['nama_lengkap'] ?? widget.userName)
                              .toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usia: ${profil['usia'] ?? '-'} thn • Tinggi: ${profil['tinggi_badan'] ?? '-'} cm',
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF64748B)),
                        ),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _metric('Berat Awal', '$beratAwal kg'),
                            _metric('Sekarang', '$beratSekarang kg'),
                            _metric('Target', '$beratTarget kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Riwayat Aktivitas Olahraga Peserta',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (aktivitas.isEmpty)
                    _emptyBox('Peserta belum memiliki riwayat olahraga.')
                  else
                    ...aktivitas.take(10).map((a) {
                      final m = a as JsonMap;
                      final rawTgl =
                          (m['tanggal_waktu'] ?? m['created_at'] ?? '')
                              .toString();
                      final tglLabel = rawTgl.contains('T')
                          ? rawTgl.split('T').first
                          : rawTgl.split(' ').first;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (m['jenis_olahraga'] ?? 'Olahraga')
                                      .toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5),
                                ),
                                Text(
                                  '${m['jarak_km'] ?? 0} km • ${m['kalori_terbakar'] ?? 0} kcal',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            Text(
                              tglLabel,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                  const Text(
                    'Catatan Berat Badan Terbaru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (beratHistory.isEmpty)
                    _emptyBox('Belum ada catatan berat badan harian.')
                  else
                    ...beratHistory.take(7).map((b) {
                      final m = b as JsonMap;
                      final tgl =
                          (m['tanggal'] ?? m['tanggal_pencatatan'] ?? '-')
                              .toString()
                              .split('T')
                              .first;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tgl,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${m['berat_badan'] ?? '-'} kg',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0066CC),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _metric(String label, String val) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        const SizedBox(height: 3),
        Text(val,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(msg,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
    );
  }
}