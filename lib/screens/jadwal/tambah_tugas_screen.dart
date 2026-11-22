import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/jadwal_item.dart';
import '../../services/jadwal_service.dart';

/// Screen untuk menambah atau mengedit jadwal latihan.
///
/// Jika [editItem] tidak null, screen berfungsi sebagai form edit.
class TambahTugasScreen extends StatefulWidget {
  final JadwalItem? editItem;

  const TambahTugasScreen({super.key, this.editItem});

  @override
  State<TambahTugasScreen> createState() => _TambahTugasScreenState();
}

class _TambahTugasScreenState extends State<TambahTugasScreen> {
  final _judulController = TextEditingController();
  bool tambahMassal = false;
  bool ulangi = true;
  bool _isSaving = false;
  int _jumlahMassalTersimpan = 0;
  FrekuensiUlang frekuensi = FrekuensiUlang.sekaliSeminggu;

  DateTime tanggalDipilih = DateTime.now();
  TimeOfDay jamDipilih = const TimeOfDay(hour: 7, minute: 0);

  bool get isEditMode => widget.editItem != null;

  static const List<String> _presetLatihan = [
    'Jalan 20 menit',
    'Berlari 30 menit',
    'Push Up 25 repetisi',
    'Plank 3 menit',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final item = widget.editItem!;
      _judulController.text = item.judul;
      tanggalDipilih = item.tanggal;
      jamDipilih =
          TimeOfDay(hour: item.tanggal.hour, minute: item.tanggal.minute);
      ulangi = item.ulangi;
      frekuensi = item.frekuensi == FrekuensiUlang.tidakUlang
          ? FrekuensiUlang.sekaliSeminggu
          : item.frekuensi;
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: tanggalDipilih,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0077E6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (hasil != null) setState(() => tanggalDipilih = hasil);
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: jamDipilih,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0077E6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (hasil != null) setState(() => jamDipilih = hasil);
  }

  Future<void> _simpan() async {
    if (_isSaving) return;

    final judul = _judulController.text.trim();
    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Nama latihan wajib diisi terlebih dahulu.'),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    final tanggalLengkap = DateTime(
      tanggalDipilih.year,
      tanggalDipilih.month,
      tanggalDipilih.day,
      jamDipilih.hour,
      jamDipilih.minute,
    );

    final frekuensiAkhir = ulangi ? frekuensi : FrekuensiUlang.tidakUlang;

    if (isEditMode) {
      final edited = widget.editItem!.copyWith(
        judul: judul,
        tanggal: tanggalLengkap,
        ulangi: ulangi,
        frekuensi: frekuensiAkhir,
      );
      Navigator.of(context).pop(edited);
      return;
    }

    final itemBaru = JadwalItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      judul: judul,
      tanggal: tanggalLengkap,
      ulangi: ulangi,
      frekuensi: frekuensiAkhir,
    );

    // Jika mode Tambah Secara Massal aktif: simpan langsung lalu reset input
    if (tambahMassal) {
      setState(() => _isSaving = true);
      await JadwalService.instance.tambahJadwal(itemBaru);
      if (!mounted) return;

      HapticFeedback.lightImpact();
      setState(() {
        _isSaving = false;
        _jumlahMassalTersimpan++;
        _judulController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"$judul" ditambahkan ($_jumlahMassalTersimpan jadwal). Silakan isi latihan berikutnya.',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    Navigator.of(context).pop(itemBaru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. HEADER MINIMALIS ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF0077E6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditMode ? 'Edit Latihan' : 'Tugas Baru',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isEditMode
                              ? 'Perbarui detail jadwal latihanmu'
                              : 'Rencanakan sesi latihan barumu',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. FORM KONTEN ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                children: [
                  // ── BAGIAN A: APA YANG HARUS DILAKUKAN ──────────
                  _buildSectionTitle(
                    icon: Icons.fitness_center_rounded,
                    title: 'Apa yang harus dilakukan?',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama & Target Latihan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _judulController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Jalan 20 menit / Push Up 25 repetisi',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(
                              Icons.directions_run_rounded,
                              color: Color(0xFF0077E6),
                              size: 20,
                            ),
                            suffixIcon: _judulController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _judulController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0077E6), width: 1.5),
                            ),
                          ),
                        ),

                        // Quick suggestion chips
                        if (!isEditMode) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _presetLatihan.map((preset) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _judulController.text = preset;
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+ $preset',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0077E6),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        if (!isEditMode) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.playlist_add_rounded,
                                  color: Color(0xFF0077E6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tambah secara massal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tetap di halaman ini setelah menyimpan untuk menambah latihan lain',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch.adaptive(
                                value: tambahMassal,
                                activeTrackColor: const Color(0xFF0077E6),
                                activeThumbColor: Colors.white,
                                onChanged: (v) =>
                                    setState(() => tambahMassal = v),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── BAGIAN B: WAKTU & NOTIFIKASI ────────────────
                  _buildSectionTitle(
                    icon: Icons.notifications_active_rounded,
                    title: 'Jadwal & Pengingat',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Picker Tanggal
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pilihTanggal,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0077E6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tanggal Pelaksanaan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('EEEE, d MMMM y', 'id_ID')
                                            .format(tanggalDipilih),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'Ubah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0077E6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Picker Waktu
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pilihJam,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.access_time_filled_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Jam Latihan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatJam(jamDipilih),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'Ubah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0077E6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── PENGATURAN PENGULANGAN (RECURRING) ──────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ulangi
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ulangi
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: ulangi
                                            ? const Color(0xFF0077E6)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.repeat_rounded,
                                        color: ulangi
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ulangi Jadwal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            'Buat jadwal otomatis setelah selesai',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: ulangi,
                                      activeTrackColor: const Color(0xFF0077E6),
                                      activeThumbColor: Colors.white,
                                      onChanged: (v) =>
                                          setState(() => ulangi = v),
                                    ),
                                  ],
                                ),
                                if (ulangi) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFrekuensiCard(
                                          title: 'Sekali Seminggu',
                                          subtitle: 'Tiap hari yang sama',
                                          icon: Icons.date_range_rounded,
                                          selected: frekuensi ==
                                              FrekuensiUlang.sekaliSeminggu,
                                          onTap: () => setState(() =>
                                              frekuensi = FrekuensiUlang
                                                  .sekaliSeminggu),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildFrekuensiCard(
                                          title: 'Sekali Sehari',
                                          subtitle: 'Berulang setiap hari',
                                          icon: Icons.today_rounded,
                                          selected: frekuensi ==
                                              FrekuensiUlang.sekaliSehari,
                                          onTap: () => setState(() =>
                                              frekuensi =
                                                  FrekuensiUlang.sekaliSehari),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 3. TOMBOL SIMPAN LATIHAN ──────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              color: const Color(0xFFF7FAFF),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _simpan,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          tambahMassal && !isEditMode
                              ? Icons.playlist_add_check_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    isEditMode
                        ? 'Simpan Perubahan'
                        : (tambahMassal
                            ? 'Simpan & Tambah Lagi'
                            : 'Simpan Latihan'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    elevation: 2,
                    shadowColor:
                        const Color(0xFF0066CC).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF0077E6)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildFrekuensiCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0077E6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF0077E6)
                : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0077E6).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF0077E6),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJam(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour.$minute $period';
  }
}