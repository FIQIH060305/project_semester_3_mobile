import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/jadwal_item.dart';

class JadwalChecklistTile extends StatelessWidget {
  final JadwalItem item;
  final VoidCallback onToggle;
  final bool terlambat;

  const JadwalChecklistTile({
    super.key,
    required this.item,
    required this.onToggle,
    this.terlambat = false,
  });

  @override
  Widget build(BuildContext context) {
    final jamFormat = DateFormat('HH.mm');
    String labelWaktu;

    if (terlambat) {
      labelWaktu = 'Hari ini, ${jamFormat.format(item.tanggal)}';
    } else if (item.kategoriWaktu == 'Hari ini') {
      labelWaktu = 'Hari ini, ${jamFormat.format(item.tanggal)}';
    } else if (item.kategoriWaktu == 'Besok') {
      labelWaktu = 'Besok, ${jamFormat.format(item.tanggal)}';
    } else {
      labelWaktu = '${DateFormat('EEEE', 'id_ID').format(item.tanggal)}, ${jamFormat.format(item.tanggal)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: terlambat ? AppColors.statRose : AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.selesai,
            activeColor: AppColors.brand,
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: item.selesai ? TextDecoration.lineThrough : null,
                    color: item.selesai ? AppColors.textGrey : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labelWaktu,
                  style: TextStyle(
                    fontSize: 12,
                    color: terlambat ? AppColors.statRose : AppColors.brand,
                    fontWeight: FontWeight.w600,
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