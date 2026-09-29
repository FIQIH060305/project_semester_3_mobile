import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/jadwal_item.dart';
import '../../widgets/button_navbar.dart';

class TambahTugasScreen extends StatefulWidget {
  const TambahTugasScreen({super.key});

  @override
  State<TambahTugasScreen> createState() => _TambahTugasScreenState();
}

class _TambahTugasScreenState extends State<TambahTugasScreen> {
  final _judulController = TextEditingController();
  bool tambahMassal = false;
  bool ulangi = true;
  String frekuensiUlang = 'Sekali seminggu';

  DateTime tanggalDipilih = DateTime.now();
  TimeOfDay jamDipilih = const TimeOfDay(hour: 12, minute: 0);

  @override
  void dispose() {
    _judulController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: tanggalDipilih,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (hasil != null) setState(() => tanggalDipilih = hasil);
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(context: context, initialTime: jamDipilih);
    if (hasil != null) setState(() => jamDipilih = hasil);
  }

  void _simpan() {
    if (_judulController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas wajib diisi.')),
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

    final itemBaru = JadwalItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      judul: _judulController.text.trim(),
      tanggal: tanggalLengkap,
      ulangi: ulangi,
    );

    Navigator.of(context).pop(itemBaru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        elevation: 0,
        title: const Text('Tugas Baru', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Apa yang harus dilakukan ?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _judulController,
                    decoration: const InputDecoration(
                      hintText: 'Jalan 20 menit',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      const Expanded(child: Text('Tambah secara massal')),
                      Switch(
                        value: tambahMassal,
                        activeColor: AppColors.brand,
                        onChanged: (v) => setState(() => tambahMassal = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pilihTanggal,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(tanggalDipilih)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  GestureDetector(
                    onTap: _pilihJam,
                    child: Row(
                      children: [
                        Expanded(child: Text(jamDipilih.format(context))),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.access_time, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.repeat, color: AppColors.brand, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Ulangi', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Switch(
                              value: ulangi,
                              activeColor: AppColors.brand,
                              onChanged: (v) => setState(() => ulangi = v),
                            ),
                          ],
                        ),
                        if (ulangi)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(frekuensiUlang, style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                backgroundColor: AppColors.brand,
                onPressed: _simpan,
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}