import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'coach_client_detail_screen.dart';
import 'coach_notifikasi_screen.dart';

class CoachMainScreen extends StatefulWidget {
  const CoachMainScreen({super.key});

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen> {
  int _tabIndex = 0;
  bool _loading = true;

  JsonMap _dashboardData = {};
  List<JsonMap> _clients = [];
  List<JsonMap> _rekomOlahraga = [];
  List<JsonMap> _rekomMakanan = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (_clients.isEmpty && _rekomOlahraga.isEmpty) {
      setState(() => _loading = true);
    }
    final auth = AuthService.instance;
    final results = await Future.wait([
      auth.fetchCoachDashboard(),
      auth.fetchCoachClients(),
      auth.fetchCoachRekomendasiOlahraga(),
      auth.fetchCoachRekomendasiMakanan(),
    ]);

    if (!mounted) return;
    setState(() {
      _dashboardData = (results[0] as JsonMap?) ?? {};
      _clients = (results[1] as List<JsonMap>?) ?? [];
      _rekomOlahraga = (results[2] as List<JsonMap>?) ?? [];
      _rekomMakanan = (results[3] as List<JsonMap>?) ?? [];
      _loading = false;
    });
  }

  JsonMap get _statistik =>
      (_dashboardData['statistik'] as JsonMap?) ?? _dashboardData;

  List<JsonMap> get _activeClients => _clients
      .where((c) =>
          (c['status_hubungan'] ?? c['status'] ?? '').toString() == 'active')
      .toList();

  List<JsonMap> get _pendingClients => _clients
      .where((c) =>
          (c['status_hubungan'] ?? c['status'] ?? '').toString() == 'pending')
      .toList();

  Future<void> _respondClient(String relId, String aksi) async {
    final res = await AuthService.instance.respondCoachClient(relId, aksi);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor:
            res.isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (res.isSuccess) _loadAll();
  }

  // ═══════════════════════════════════════════════════════════════════
  // MODAL TAMBAH / EDIT REKOMENDASI JADWAL OLAHRAGA
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _openFormOlahraga({JsonMap? existing}) async {
    if (_activeClients.isEmpty && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum memiliki peserta aktif untuk diberi jadwal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String selectedUserId = existing != null
        ? (existing['user_id'] ?? '').toString()
        : (_activeClients.first['id_akun'] ??
                _activeClients.first['user_id'] ??
                _activeClients.first['user']?['id_akun'] ??
                '')
            .toString();

    final namaOlahragaCtrl = TextEditingController(
      text: (existing?['nama_olahraga'] ?? existing?['judul_latihan'] ?? '')
          .toString(),
    );
    final deskripsiCtrl = TextEditingController(
      text: (existing?['deskripsi'] ?? '').toString(),
    );
    final durasiCtrl = TextEditingController(
      text: (existing?['durasi'] ?? existing?['durasi_menit'] ?? '30')
          .toString(),
    );
    final waktuCtrl = TextEditingController(
      text: (existing?['waktu'] ?? existing?['waktu_latihan'] ?? '07:00')
          .toString(),
    );
    final targetCtrl = TextEditingController(
      text: (existing?['target'] ?? '').toString(),
    );
    final catatanCtrl = TextEditingController(
      text: (existing?['catatan'] ?? '').toString(),
    );
    String intensitas = (existing?['intensitas'] ?? 'Sedang').toString();
    DateTime tanggal = DateTime.tryParse(
          (existing?['tanggal'] ?? existing?['tanggal_latihan'] ?? '')
              .toString(),
        ) ??
        DateTime.now().add(const Duration(days: 1));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      existing == null
                          ? 'Kirim Rekomendasi Jadwal Olahraga'
                          : 'Edit Rekomendasi Jadwal Olahraga',
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    if (existing == null) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedUserId,
                        decoration: _inputDeco('Pilih Peserta'),
                        items: _activeClients.map((c) {
                          final u = c['user'] as JsonMap? ?? c;
                          final uid = (c['id_akun'] ??
                                  c['user_id'] ??
                                  u['id_akun'] ??
                                  '')
                              .toString();
                          final uname = (c['nama_lengkap'] ??
                                  u['nama_lengkap'] ??
                                  'Peserta GERAK')
                              .toString();
                          return DropdownMenuItem(
                              value: uid, child: Text(uname));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedUserId = v);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: namaOlahragaCtrl,
                      decoration:
                          _inputDeco('Nama Olahraga (mis. Jogging Pagi)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: deskripsiCtrl,
                      decoration:
                          _inputDeco('Deskripsi Singkat Latihan (opsional)'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durasiCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco('Durasi (menit)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: waktuCtrl,
                            decoration: _inputDeco('Jam (07:00)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: ['Ringan', 'Sedang', 'Berat']
                                    .contains(intensitas)
                                ? intensitas
                                : 'Sedang',
                            decoration: _inputDeco('Intensitas'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Ringan', child: Text('Ringan')),
                              DropdownMenuItem(
                                  value: 'Sedang', child: Text('Sedang')),
                              DropdownMenuItem(
                                  value: 'Berat', child: Text('Berat')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => intensitas = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: targetCtrl,
                            decoration: _inputDeco('Target (mis. 3 km)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tanggal,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => tanggal = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 17),
                      label: Text(
                        'Tanggal: ${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: catatanCtrl,
                      maxLines: 2,
                      decoration: _inputDeco('Catatan instruksi Pelatih'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (namaOlahragaCtrl.text.trim().isEmpty) return;
                        final tglStr =
                            '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
                        final res = await AuthService.instance
                            .saveCoachRekomendasiOlahraga(
                          id: existing?['id']?.toString(),
                          payload: {
                            'user_id': int.tryParse(selectedUserId) ??
                                selectedUserId,
                            'nama_olahraga': namaOlahragaCtrl.text.trim(),
                            if (deskripsiCtrl.text.trim().isNotEmpty)
                              'deskripsi': deskripsiCtrl.text.trim(),
                            'tanggal': tglStr,
                            'waktu': waktuCtrl.text.trim().isEmpty
                                ? '07:00'
                                : waktuCtrl.text.trim(),
                            'durasi':
                                int.tryParse(durasiCtrl.text.trim()) ?? 30,
                            'intensitas': intensitas,
                            if (targetCtrl.text.trim().isNotEmpty)
                              'target': targetCtrl.text.trim(),
                            if (catatanCtrl.text.trim().isNotEmpty)
                              'catatan': catatanCtrl.text.trim(),
                          },
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.isSuccess
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (res.isSuccess) _loadAll();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Kirim Rekomendasi Olahraga',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MODAL TAMBAH / EDIT REKOMENDASI MAKANAN DIET
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _openFormMakanan({JsonMap? existing}) async {
    if (_activeClients.isEmpty && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum memiliki peserta aktif.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String selectedUserId = existing != null
        ? (existing['user_id'] ?? '').toString()
        : (_activeClients.first['id_akun'] ??
                _activeClients.first['user_id'] ??
                _activeClients.first['user']?['id_akun'] ??
                '')
            .toString();

    final namaMakananCtrl = TextEditingController(
      text: (existing?['nama_makanan'] ?? existing?['nama_menu'] ?? '')
          .toString(),
    );
    final deskripsiCtrl = TextEditingController(
      text: (existing?['deskripsi'] ?? '').toString(),
    );
    final kaloriCtrl = TextEditingController(
      text: (existing?['kalori'] ?? existing?['kalori_kkal'] ?? '350')
          .toString(),
    );
    final proteinCtrl = TextEditingController(
      text: (existing?['protein'] ?? '25').toString(),
    );
    final karboCtrl = TextEditingController(
      text: (existing?['karbohidrat'] ?? '40').toString(),
    );
    final lemakCtrl = TextEditingController(
      text: (existing?['lemak'] ?? '10').toString(),
    );
    final waktuKonsumsiCtrl = TextEditingController(
      text: (existing?['waktu_konsumsi'] ?? '07:30').toString(),
    );
    final catatanCtrl = TextEditingController(
      text: (existing?['catatan'] ?? '').toString(),
    );
    String kategori =
        (existing?['kategori'] ?? existing?['waktu_makan'] ?? 'Sarapan')
            .toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      existing == null
                          ? 'Kirim Rekomendasi Makanan Diet'
                          : 'Edit Rekomendasi Makanan Diet',
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    if (existing == null) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedUserId,
                        decoration: _inputDeco('Pilih Peserta'),
                        items: _activeClients.map((c) {
                          final u = c['user'] as JsonMap? ?? c;
                          final uid = (c['id_akun'] ??
                                  c['user_id'] ??
                                  u['id_akun'] ??
                                  '')
                              .toString();
                          final uname = (c['nama_lengkap'] ??
                                  u['nama_lengkap'] ??
                                  'Peserta GERAK')
                              .toString();
                          return DropdownMenuItem(
                              value: uid, child: Text(uname));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedUserId = v);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: [
                              'Sarapan',
                              'Makan Siang',
                              'Makan Malam',
                              'Camilan'
                            ].contains(kategori)
                                ? kategori
                                : 'Sarapan',
                            decoration: _inputDeco('Kategori Waktu'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Sarapan', child: Text('Sarapan')),
                              DropdownMenuItem(
                                  value: 'Makan Siang',
                                  child: Text('Makan Siang')),
                              DropdownMenuItem(
                                  value: 'Makan Malam',
                                  child: Text('Makan Malam')),
                              DropdownMenuItem(
                                  value: 'Camilan', child: Text('Camilan')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => kategori = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: waktuKonsumsiCtrl,
                            decoration: _inputDeco('Jam (07:30)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: namaMakananCtrl,
                      decoration: _inputDeco('Nama Menu Diet'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: deskripsiCtrl,
                      decoration:
                          _inputDeco('Deskripsi Menu / Bahan (opsional)'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: kaloriCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco('Kalori (kkal)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: proteinCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDeco('Protein (g)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: karboCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDeco('Karbohidrat (g)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: lemakCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDeco('Lemak (g)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: catatanCtrl,
                      maxLines: 2,
                      decoration: _inputDeco('Catatan saran penyajian Pelatih'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (namaMakananCtrl.text.trim().isEmpty) return;
                        final res = await AuthService.instance
                            .saveCoachRekomendasiMakanan(
                          id: existing?['id']?.toString(),
                          payload: {
                            'user_id': int.tryParse(selectedUserId) ??
                                selectedUserId,
                            'kategori': kategori,
                            'nama_makanan': namaMakananCtrl.text.trim(),
                            if (deskripsiCtrl.text.trim().isNotEmpty)
                              'deskripsi': deskripsiCtrl.text.trim(),
                            'kalori':
                                int.tryParse(kaloriCtrl.text.trim()) ?? 350,
                            'protein':
                                double.tryParse(proteinCtrl.text.trim()) ?? 0,
                            'karbohidrat':
                                double.tryParse(karboCtrl.text.trim()) ?? 0,
                            'lemak':
                                double.tryParse(lemakCtrl.text.trim()) ?? 0,
                            if (waktuKonsumsiCtrl.text.trim().isNotEmpty)
                              'waktu_konsumsi': waktuKonsumsiCtrl.text.trim(),
                            if (catatanCtrl.text.trim().isNotEmpty)
                              'catatan': catatanCtrl.text.trim(),
                          },
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.isSuccess
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (res.isSuccess) _loadAll();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Simpan Rekomendasi Makanan',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coach = AuthService.instance.currentUser?.coach;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portal Pelatih GERAK',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              coach?.nama ??
                  AuthService.instance.currentUser?.name ??
                  'Pelatih',
              style: const TextStyle(
                color: Color(0xFF0066CC),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CoachNotifikasiScreen()),
              );
            },
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF0F172A)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _tabIndex,
              children: [
                _buildDashboardTab(),
                _buildClientsTab(),
                _buildRekomendasiTab(),
                _buildProfilTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0066CC),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), label: 'Peserta'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in_rounded), label: 'Program'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  // ── TAB 0: BERANDA PELATIH ─────────────────────────────────────────
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Banner Sambutan Pelatih
                Container(
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF005BAC), Color(0xFF0077E6)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pendampingan Kebugaran',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Halo, ${AuthService.instance.currentUser?.name ?? 'Pelatih'}!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pantau progres peserta dan kirim jadwal latihan terukur hari ini.',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.sports_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),

                // Statistik 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _statCard(
                      'Peserta Aktif',
                      '${_statistik['jumlah_klien_aktif'] ?? _activeClients.length}',
                      Icons.groups_rounded,
                      const Color(0xFF0066CC),
                    ),
                    _statCard(
                      'Permintaan Baru',
                      '${_statistik['permintaan_pending'] ?? _pendingClients.length}',
                      Icons.person_add_alt_1_rounded,
                      const Color(0xFFD97706),
                    ),
                    _statCard(
                      'Jadwal Olahraga',
                      '${_statistik['total_rekom_olahraga'] ?? _rekomOlahraga.length}',
                      Icons.fitness_center_rounded,
                      const Color(0xFF16A34A),
                    ),
                    _statCard(
                      'Menu Diet',
                      '${_statistik['total_rekom_makanan'] ?? _rekomMakanan.length}',
                      Icons.restaurant_menu_rounded,
                      const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tombol Aksi Cepat
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openFormOlahraga(),
                        icon:
                            const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Beri Jadwal Olahraga',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066CC),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openFormMakanan(),
                        icon: const Icon(Icons.restaurant_rounded,
                            color: Colors.white),
                        label: const Text('Beri Menu Diet',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_pendingClients.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Permintaan Pendampingan Peserta',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ..._pendingClients
                      .map((c) => _buildClientCard(c, isPending: true)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B))),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: PESERTA DAMPINGAN ───────────────────────────────────────
  Widget _buildClientsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_pendingClients.isNotEmpty) ...[
                  const Text('Permintaan Peserta Baru',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ..._pendingClients
                      .map((c) => _buildClientCard(c, isPending: true)),
                  const SizedBox(height: 16),
                ],
                const Text('Peserta Aktif Saya',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_activeClients.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Belum ada peserta aktif yang kamu dampingi.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
              ]),
            ),
          ),
          if (_activeClients.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              sliver: SliverList.builder(
                itemCount: _activeClients.length,
                itemBuilder: (context, index) =>
                    _buildClientCard(_activeClients[index], isPending: false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientCard(JsonMap rel, {required bool isPending}) {
    final user = rel['user'] as JsonMap? ?? rel;
    final relId = (rel['relasi_id'] ?? rel['id'] ?? '').toString();
    final uid =
        (rel['id_akun'] ?? rel['user_id'] ?? user['id_akun'] ?? '').toString();
    final nama =
        (rel['nama_lengkap'] ?? user['nama_lengkap'] ?? 'Peserta GERAK')
            .toString();
    final beratSekarang =
        rel['berat_sekarang'] ?? user['berat_sekarang'] ?? '-';
    final beratTarget = rel['berat_target'] ?? user['berat_target'] ?? '-';
    final catatan = (rel['catatan_pengajuan'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              CircleAvatar(
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF0066CC)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w800)),
                    Text(
                      'Berat: $beratSekarang kg • Target: $beratTarget kg',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    if (isPending && catatan.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '"$catatan"',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isPending)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CoachClientDetailScreen(
                          userId: uid,
                          userName: nama,
                        ),
                      ),
                    );
                  },
                  child: const Text('Detail Progres',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondClient(relId, 'reject'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626)),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondClient(relId, 'approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white),
                    child: const Text('Terima Peserta'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 2: PROGRAM & REKOMENDASI (CRUD + STATUS PERSETUJUAN PESERTA) ─
  Widget _buildRekomendasiTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF0066CC),
              unselectedLabelColor: Color(0xFF64748B),
              indicatorColor: Color(0xFF0066CC),
              tabs: [
                Tab(text: 'Jadwal Olahraga'),
                Tab(text: 'Makanan Diet'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListOlahraga(),
                _buildListMakanan(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPersetujuanBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'accepted':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Diterima Peserta';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Ditolak Peserta';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Menunggu Konfirmasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _buildListOlahraga() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(
              child: ElevatedButton.icon(
                onPressed: () => _openFormOlahraga(),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Kirim Rekomendasi Jadwal Olahraga',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          if (_rekomOlahraga.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Belum ada rekomendasi jadwal olahraga.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList.builder(
                itemCount: _rekomOlahraga.length,
                itemBuilder: (context, index) {
                  final item = _rekomOlahraga[index];
                  final id = (item['id'] ?? '').toString();
                  final peserta = (item['nama_user'] ??
                          item['user']?['nama_lengkap'] ??
                          'Peserta')
                      .toString();
                  final judul = (item['nama_olahraga'] ??
                          item['judul_latihan'] ??
                          'Latihan')
                      .toString();
                  final tgl = (item['tanggal'] ??
                          item['tanggal_latihan'] ??
                          '')
                      .toString();
                  final durasi = item['durasi'] ?? item['durasi_menit'] ?? 0;
                  final statusUser =
                      (item['status_user'] ?? item['status'] ?? 'pending')
                          .toString();
                  final alasanTolak =
                      (item['alasan_penolakan'] ?? '').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(judul,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Peserta: $peserta • $tgl ($durasi mnt • ${item['intensitas'] ?? 'Sedang'})',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  color: Color(0xFF0066CC), size: 20),
                              onPressed: () =>
                                  _openFormOlahraga(existing: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626), size: 20),
                              onPressed: () async {
                                final ok = await AuthService.instance
                                    .deleteCoachRekomendasiOlahraga(id);
                                if (ok) _loadAll();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildStatusPersetujuanBadge(statusUser),
                        if (statusUser == 'rejected' &&
                            alasanTolak.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Alasan penolakan: "$alasanTolak"',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListMakanan() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(
              child: ElevatedButton.icon(
                onPressed: () => _openFormMakanan(),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Kirim Rekomendasi Makanan Diet',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          if (_rekomMakanan.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Belum ada rekomendasi makanan diet.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList.builder(
                itemCount: _rekomMakanan.length,
                itemBuilder: (context, index) {
                  final item = _rekomMakanan[index];
                  final id = (item['id'] ?? '').toString();
                  final peserta = (item['nama_user'] ??
                          item['user']?['nama_lengkap'] ??
                          'Peserta')
                      .toString();
                  final kategori =
                      (item['kategori'] ?? item['waktu_makan'] ?? 'Menu')
                          .toString();
                  final namaMenu =
                      (item['nama_makanan'] ?? item['nama_menu'] ?? '')
                          .toString();
                  final kalori = item['kalori'] ?? item['kalori_kkal'] ?? 0;
                  final protein = item['protein'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('[$kategori] $namaMenu',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(
                                'Peserta: $peserta • $kalori kkal • Protein ${protein}g',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              color: Color(0xFF0066CC), size: 20),
                          onPressed: () => _openFormMakanan(existing: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626), size: 20),
                          onPressed: () async {
                            final ok = await AuthService.instance
                                .deleteCoachRekomendasiMakanan(id);
                            if (ok) _loadAll();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── TAB 3: PROFIL PELATIH ──────────────────────────────────────────
  Widget _buildProfilTab() {
    final user = AuthService.instance.currentUser;
    final coach = user?.coach;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFDBEAFE),
                    child: Icon(Icons.sports_rounded,
                        color: Color(0xFF0066CC), size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach?.nama ?? user?.name ?? 'Pelatih GERAK',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        Text(user?.email ?? '-',
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Pelatih Terverifikasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _infoRow('Tempat, Tanggal Lahir',
                  '${coach?.tempatLahir ?? '-'}, ${coach?.tanggalLahir ?? '-'} (${coach?.usia ?? '-'} thn)'),
              _infoRow('Nomor Handphone', coach?.noHp ?? '-'),
              _infoRow('Spesialisasi', coach?.spesialisasi ?? '-'),
              _infoRow('Bio / Pengalaman', coach?.bio ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await AuthService.instance.logout();
            if (!mounted) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          label: const Text('Keluar dari Akun Pelatih',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}