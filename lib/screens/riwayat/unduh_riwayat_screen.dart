import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/riwayat_item.dart';

class UnduhRiwayatScreen extends StatelessWidget {
  final RiwayatItem item;
  const UnduhRiwayatScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFF3F6B8C), Color(0xFF6FAF7C)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${item.tanggal.day} September ${item.tanggal.year}, ${item.tanggal.hour.toString().padLeft(2, '0')}.${item.tanggal.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 20),
                      const Text('Jarak', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${item.jarakKm} KM', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      const Text('Waktu', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(item.waktuFormat, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      const Text('Langkah', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${item.langkah}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 24),
                      const Text('GERAK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kartu riwayat berhasil disimpan (dummy, belum tersambung ke galeri).')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}