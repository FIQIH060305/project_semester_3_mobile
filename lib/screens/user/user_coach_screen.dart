import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class UserCoachScreen extends StatefulWidget {
  const UserCoachScreen({super.key});

  @override
  State<UserCoachScreen> createState() => _UserCoachScreenState();
}

class _UserCoachScreenState extends State<UserCoachScreen> {
  bool _loading = true;
  JsonMap? _myCoach;
  List<JsonMap> _coaches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await Future.wait([
      AuthService.instance.fetchMyCoach(),
      AuthService.instance.fetchAvailableCoaches(),
    ]);
    if (!mounted) return;
    setState(() {
      _myCoach = res[0] as JsonMap?;
      _coaches = (res[1] as List<JsonMap>?) ?? [];
      _loading = false;
    });
  }

  Future<void> _ajukanCoach(String coachId, String namaCoach) async {
    final catatanCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pilih Coach $namaCoach',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: catatanCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Tuliskan target atau kondisi kebugaranmu untuk Coach (opsional)...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white),
            child: const Text('Kirim Permintaan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await AuthService.instance
        .pilihCoach(coachId, catatan: catatanCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor:
            res.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (res.isSuccess) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final activeCoach = _myCoach?['coach'] as JsonMap?;
    final relStatus = (_myCoach?['status'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Coach Pendamping Saya',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (activeCoach != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF005BAC), Color(0xFF0077E6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Coach Pendamping Kamu',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  relStatus == 'active'
                                      ? 'Aktif'
                                      : 'Menunggu Persetujuan',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0066CC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (activeCoach['nama'] ?? 'Coach GERAK').toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (activeCoach['spesialisasi'] ??
                                    'Pelatih Kebugaran & Diet')
                                .toString(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'HP: ${activeCoach['no_hp'] ?? '-'} • Usia: ${activeCoach['usia'] ?? '-'} thn',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    'Daftar Coach Terverifikasi',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_coaches.isEmpty)
                    const Text('Belum ada Coach terverifikasi saat ini.',
                        style: TextStyle(color: Color(0xFF64748B)))
                  else
                    ..._coaches.map((c) {
                      final cid = (c['id'] ?? '').toString();
                      final nama = (c['nama'] ?? 'Coach').toString();
                      final isCurrent = activeCoach != null &&
                          activeCoach['id']?.toString() == cid;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFDBEAFE),
                                  child: Icon(Icons.sports_rounded,
                                      color: Color(0xFF0066CC)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(nama,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800)),
                                      Text(
                                        (c['spesialisasi'] ??
                                                'Pelatih Kebugaran')
                                            .toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0066CC),
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (c['bio'] != null &&
                                c['bio'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                c['bio'].toString(),
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
                                    height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isCurrent
                                    ? null
                                    : () => _ajukanCoach(cid, nama),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066CC),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isCurrent
                                      ? 'Coach Terpilih'
                                      : 'Pilih Coach Ini',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
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
}