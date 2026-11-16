import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';

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
  FrekuensiUlang frekuensi = FrekuensiUlang.sekaliSeminggu;

  DateTime tanggalDipilih = DateTime.now();
  TimeOfDay jamDipilih = const TimeOfDay(hour: 12, minute: 0);

  bool get isEditMode => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final item = widget.editItem!;
      _judulController.text = item.judul;
      tanggalDipilih = item.tanggal;
      jamDipilih = TimeOfDay(hour: item.tanggal.hour, minute: item.tanggal.minute);
      ulangi = item.ulangi;
      frekuensi = item.frekuensi;
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
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
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
              primary: AppColors.brand,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (hasil != null) setState(() => jamDipilih = hasil);
  }

  void _simpan() {
    final judul = _judulController.text.trim();
    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Nama latihan wajib diisi.'),
            ],
          ),
          backgroundColor: const Color(0xFFD84343),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      // Kembalikan item yang sudah diedit dengan ID yang sama
      final edited = widget.editItem!.copyWith(
        judul: judul,
        tanggal: tanggalLengkap,
        ulangi: ulangi,
        frekuensi: frekuensiAkhir,
      );
      Navigator.of(context).pop(edited);
    } else {
      // Buat item baru
      final itemBaru = JadwalItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        judul: judul,
        tanggal: tanggalLengkap,
        ulangi: ulangi,
        frekuensi: frekuensiAkhir,
      );
      Navigator.of(context).pop(itemBaru);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.brand, size: 32),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditMode ? 'Edit Latihan' : 'Tugas Baru',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 12),

                  // ── Section: Apa yang harus dilakukan ───────
                  _buildSectionLabel('Apa yang harus dilakukan ?'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _judulController,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Jalan 20 menit',
                            hintStyle: TextStyle(color: AppColors.textGrey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Tambah secara massal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Switch(
                                value: tambahMassal,
                                activeTrackColor: AppColors.brand,
                                activeThumbColor: Colors.white,
                                onChanged: (v) =>
                                    setState(() => tambahMassal = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section: Notifikasi ────────────────────
                  _buildSectionLabel('Notifikasi'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        // Pilih Tanggal
                        GestureDetector(
                          onTap: _pilihTanggal,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, d MMMM y', 'id_ID')
                                      .format(tanggalDipilih),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.brand,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.calendar_today_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 28, color: AppColors.border),

                        // Pilih Waktu
                        GestureDetector(
                          onTap: _pilihJam,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatJam(jamDipilih),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.brand,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.access_time_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Pengulangan / Ulangi ─────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sync_rounded,
                                      color: AppColors.brand, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Ulangi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: ulangi,
                                    activeTrackColor: AppColors.brand,
                                    activeThumbColor: Colors.white,
                                    onChanged: (v) =>
                                        setState(() => ulangi = v),
                                  ),
                                ],
                              ),
                              if (ulangi) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildFrekuensiChip(
                                      label: 'Sekali seminggu',
                                      selected: frekuensi ==
                                          FrekuensiUlang.sekaliSeminggu,
                                      onTap: () => setState(() => frekuensi =
                                          FrekuensiUlang.sekaliSeminggu),
                                    ),
                                    const SizedBox(width: 10),
                                    _buildFrekuensiChip(
                                      label: 'Sekali Sehari',
                                      selected: frekuensi ==
                                          FrekuensiUlang.sekaliSehari,
                                      onTap: () => setState(() => frekuensi =
                                          FrekuensiUlang.sekaliSehari),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Tombol Simpan Latihan ───────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isEditMode ? 'Simpan Perubahan' : 'Simpan Latihan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.brand,
        ),
      ),
    );
  }

  Widget _buildFrekuensiChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textDark,
          ),
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
