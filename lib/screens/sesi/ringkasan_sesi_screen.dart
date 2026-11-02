import 'package:flutter/material.dart';
import '../../models/riwayat_item.dart';
import 'services/tracking_calculator.dart';

class RingkasanSesiScreen extends StatelessWidget {
  final String jenisOlahraga; // 'Berjalan' atau 'Berlari'
  final String tanggal;
  final String durasiMenit;
  final String durasiFormatted;
  final String jarakKm;
  final String langkah;
  final bool isStepEstimated;
  final String kalori;
  final String paceRataRata;
  final String detakJantung;
  final List<SplitKilometer> splitList;
  final List<double>? kecepatanSeries;

  const RingkasanSesiScreen({
    super.key,
    this.jenisOlahraga = 'Berjalan',
    this.tanggal = 'Hari ini',
    this.durasiMenit = '20',
    this.durasiFormatted = '00:20:00',
    this.jarakKm = '1,8',
    this.langkah = '2.430',
    this.isStepEstimated = false,
    this.kalori = '145',
    this.paceRataRata = "11’06” /km",
    this.detakJantung = '108 bpm',
    this.splitList = const [],
    this.kecepatanSeries,
  });

  void _simpanDanKembali(BuildContext context) {
    // 1. Parse dan simpan ke database / riwayat in-memory
    final jarakClean = double.tryParse(jarakKm.replaceAll(',', '.')) ?? 0.0;
    final kaloriClean = int.tryParse(kalori) ?? 0;
    final durasiClean = int.tryParse(durasiMenit) ?? 1;
    final langkahClean = int.tryParse(langkah.replaceAll('.', '')) ?? 0;

    final itemBaru = RiwayatItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jenis: jenisOlahraga,
      tanggal: DateTime.now(),
      jarakKm: jarakClean,
      kalori: kaloriClean,
      waktuMenit: durasiClean > 0 ? durasiClean : 1,
      langkah: langkahClean,
      kecepatanSeries: kecepatanSeries ?? [3.0, 4.0, 5.0, 6.0, 5.0, 4.0],
    );

    simpanRiwayatBaru(itemBaru);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aktivitas $jenisOlahraga berhasil disimpan ke Riwayat!'),
        backgroundColor: const Color(0xFF0077E6),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 2. Kembali ke Dashboard utama
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFBFDBFE),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // GERAK Logo
                Image.asset(
                  'assets/images/logo_gerak.png',
                  height: 48,
                  errorBuilder: (_, __, ___) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0077E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GERAK',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0077E6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Title: Jenis Olahraga & Tanggal
                Text(
                  jenisOlahraga,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggal,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Row 1: Durasi & Jarak
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'DURASI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: durasiMenit,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' menit',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0077E6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'JARAK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: jarakKm,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' km',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0077E6),
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
                const SizedBox(height: 12),

                // Row 2: Langkah & Kalori (Divided Card)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Langkah
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  langkah,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'langkah',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    if (isStepEstimated)
                                      const Text(
                                        ' (est)',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0077E6),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1.2,
                        color: const Color(0xFFE2E8F0),
                      ),
                      // Kalori
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF3C7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFD97706),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: kalori,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' kcal',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'terbakar (MET)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Row 3: Pace Rata-rata & Detak Jantung
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rata-rata Pace: $paceRataRata',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0077E6),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Detak Jantung: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0077E6),
                              ),
                            ),
                            TextSpan(
                              text: detakJantung,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Card: Progres Sesi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Progres Sesi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0077E6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: const LinearProgressIndicator(
                          value: 1.0,
                          minHeight: 9,
                          backgroundColor: Color(0xFFDBEAFE),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077E6)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        jenisOlahraga == 'Berlari'
                            ? '“Hebat! Sesi lari selesai. Pembakaran kalori dan stamina fisikmu berkembang sangat optimal hari ini.”'
                            : '“Luar biasa! Target langkah tercapai. Konsistensi bergerak adalah kunci menjaga metabolisme dan kesehatan tubuh.”',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card: Riwayat Split Kilometer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riwayat Split Kilometer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (splitList.isNotEmpty) ...[
                        for (int i = 0; i < splitList.length; i++) ...[
                          _buildSplitItem(
                            nomor: '${splitList[i].kilometerKe}',
                            label: 'Kilometer ${splitList[i].kilometerKe}',
                            subLabel: splitList[i].isTercepat
                                ? "${splitList[i].paceFormatted} pace (Tercepat)"
                                : "${splitList[i].paceFormatted} pace",
                            waktu: splitList[i].durasiFormatted,
                            isHighlight: splitList[i].isTercepat,
                          ),
                          if (i < splitList.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ),
                        ],
                      ] else ...[
                        // Jika aktivitas kurang dari 1 km
                        _buildSplitItem(
                          nomor: '1',
                          label: 'Jarak Tempuh ($jarakKm km)',
                          subLabel: '$paceRataRata pace',
                          waktu: durasiFormatted.substring(3), // mm:ss
                          isHighlight: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button: Simpan & Kembali Ke Dashboard
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _simpanDanKembali(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077E6),
                      elevation: 4,
                      shadowColor: const Color(0xFF0077E6).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Simpan & Kembali Ke Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitItem({
    required String nomor,
    required String label,
    required String subLabel,
    required String waktu,
    required bool isHighlight,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            nomor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Text(
          subLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            color: isHighlight ? const Color(0xFF0077E6) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          waktu,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
