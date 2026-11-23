import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../models/riwayat_item.dart';
import '../../services/auth_service.dart';
import '../../widgets/gerak_animations.dart';
import '../riwayat/riwayat_olahraga_screen.dart';
import 'services/tracking_calculator.dart';
import 'widgets/osm_tracking_map.dart';

class RingkasanSesiScreen extends StatefulWidget {
  final String jenisOlahraga;
  final String tanggal;
  final String durasiMenit;
  final String durasiFormatted;
  final String jarakKm;
  final double? jarakMeter;
  final String langkah;
  final bool sensorLangkahTersedia;
  final bool isStepEstimated;
  final String kalori;
  final String paceRataRata;
  final double? kecepatanRataRataKmh;
  final String detakJantung;
  final List<SplitKilometer> splitList;
  final List<double>? kecepatanSeries;
  final List<LatLng> rutePoints;
  final String? syncMessage;
  final bool isSynced;

  const RingkasanSesiScreen({
    super.key,
    this.jenisOlahraga = 'Berjalan',
    this.tanggal = 'Hari ini',
    this.durasiMenit = '20',
    this.durasiFormatted = '00:20:00',
    this.jarakKm = '1,80',
    this.jarakMeter,
    this.langkah = '2.430',
    this.sensorLangkahTersedia = true,
    this.isStepEstimated = false,
    this.kalori = '145',
    this.paceRataRata = "11’06” /km",
    this.kecepatanRataRataKmh,
    this.detakJantung = '108 bpm',
    this.splitList = const [],
    this.kecepatanSeries,
    this.rutePoints = const [],
    this.syncMessage,
    this.isSynced = true,
  });

  @override
  State<RingkasanSesiScreen> createState() => _RingkasanSesiScreenState();
}

class _RingkasanSesiScreenState extends State<RingkasanSesiScreen> {
  bool _alreadySaved = false;

  @override
  void initState() {
    super.initState();
    if (widget.syncMessage != null) {
      _alreadySaved = true;
    } else {
      _autoPersistIfNeeded();
    }
  }

  Future<void> _autoPersistIfNeeded() async {
    if (_alreadySaved) return;
    _alreadySaved = true;

    final jarakClean =
        double.tryParse(widget.jarakKm.replaceAll(',', '.')) ?? 0.0;
    final kaloriClean =
        double.tryParse(widget.kalori.replaceAll(',', '.')) ?? 0.0;
    final durasiClean = int.tryParse(widget.durasiMenit) ?? 1;
    final langkahClean =
        int.tryParse(widget.langkah.replaceAll('.', '')) ?? 0;

    final parts = widget.durasiFormatted.split(':');
    int durasiDetik = durasiClean * 60;
    if (parts.length == 3) {
      durasiDetik = ((int.tryParse(parts[0]) ?? 0) * 3600) +
          ((int.tryParse(parts[1]) ?? 0) * 60) +
          (int.tryParse(parts[2]) ?? 0);
    }

    final itemBaru = RiwayatItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jenis: widget.jenisOlahraga,
      tanggal: DateTime.now(),
      jarakKm: jarakClean,
      kalori: kaloriClean.round(),
      waktuMenit: durasiClean > 0 ? durasiClean : 1,
      durasiDetik: durasiDetik > 0 ? durasiDetik : 60,
      langkah: langkahClean,
      sensorLangkahTersedia: widget.sensorLangkahTersedia,
      paceRataRata: widget.paceRataRata,
      kecepatanRataRataKmh: widget.kecepatanRataRataKmh,
      kecepatanSeries: widget.kecepatanSeries ?? const [3.5, 4.5, 5.2, 4.8],
      rutePoints: widget.rutePoints,
    );
    await RiwayatService.instance.tambahAktivitas(itemBaru);
    await AuthService.instance.simpanAktivitasKeServer(
      jenisOlahraga: widget.jenisOlahraga,
      jarakKm: jarakClean,
      durasiDetik: durasiDetik > 0 ? durasiDetik : 60,
      jumlahLangkah: langkahClean,
      kaloriTerbakar: kaloriClean,
    );
  }

  @override
  Widget build(BuildContext context) {
    final jarakClean =
        double.tryParse(widget.jarakKm.replaceAll(',', '.')) ?? 0.0;
    final meterVal = widget.jarakMeter ?? (jarakClean * 1000.0);
    final durasiMenitInt = int.tryParse(widget.durasiMenit) ?? 1;
    final avgSpeed = widget.kecepatanRataRataKmh ??
        (durasiMenitInt > 0 ? (jarakClean / (durasiMenitInt / 60.0)) : 0.0);

    final tanggalLengkap =
        DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Ringkasan Aktivitas',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          child: Column(
            children: [
              // ── 1. KARTU APPRESIASI & IDENTITAS SESI ────────────────
              GerakEntrance(
                delayMs: 40,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0077E6), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0077E6).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              widget.jenisOlahraga == 'Berjalan'
                                  ? Icons.directions_walk_rounded
                                  : Icons.directions_run_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.jenisOlahraga,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tanggalLengkap,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Tersimpan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Kerja bagus! Kamu sudah menyelesaikan aktivitas hari ini. Terus bergerak dan capai targetmu!',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 2. PETA RUTE PERJALANAN OPENSTREETMAP ───────────────
              GerakEntrance(
                delayMs: 90,
                child: Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: widget.rutePoints.isNotEmpty
                      ? OsmTrackingMap(
                          rutePoints: widget.rutePoints,
                          posisiAwal: widget.rutePoints.first,
                          posisiSaatIni: widget.rutePoints.last,
                          followUser: false,
                          isReadOnly: true,
                          borderRadius: 22,
                          gpsStatusText:
                              'Rute Perjalanan (${widget.rutePoints.length} titik GPS)',
                          gpsStatusColor: const Color(0xFF0077E6),
                          onToggleFollow: () {},
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.map_outlined,
                                color: Color(0xFF0077E6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Peta Rute Tidak Tersedia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Belum cukup titik GPS terekam selama sesi ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 3. GRID STATISTIK HASIL AKTIVITAS ───────────────────
              GerakEntrance(
                delayMs: 140,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricTile(
                            label: 'Total Durasi',
                            value: widget.durasiFormatted,
                            subInfo: '${widget.durasiMenit} menit aktif',
                            icon: Icons.timer_rounded,
                            accentColor: const Color(0xFF0077E6),
                            iconBg: const Color(0xFFDBEAFE),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryMetricTile(
                            label: 'Total Jarak',
                            value: '${widget.jarakKm} km',
                            subInfo: '${meterVal.round()} meter',
                            icon: Icons.route_rounded,
                            accentColor: const Color(0xFF0284C7),
                            iconBg: const Color(0xFFE0F2FE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricTile(
                            label: 'Jumlah Langkah',
                            value: widget.langkah,
                            subInfo: widget.isStepEstimated
                                ? 'Estimasi berdasarkan jarak'
                                : 'Tercatat dari sensor',
                            icon: Icons.directions_walk_rounded,
                            accentColor: const Color(0xFF0EA5E9),
                            iconBg: const Color(0xFFE0F2FE),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryMetricTile(
                            label: 'Kalori Terbakar',
                            value: '${widget.kalori} kcal',
                            subInfo: 'Estimasi (MET & berat badan)',
                            icon: Icons.local_fire_department_rounded,
                            accentColor: const Color(0xFFF59E0B),
                            iconBg: const Color(0xFFFEF3C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricTile(
                            label: 'Pace Rata-rata',
                            value: widget.paceRataRata,
                            subInfo: 'Ritme per kilometer',
                            icon: Icons.av_timer_rounded,
                            accentColor: const Color(0xFF0077E6),
                            iconBg: const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryMetricTile(
                            label: 'Kecepatan Rata-rata',
                            value: '${avgSpeed.toStringAsFixed(1)} km/jam',
                            subInfo: 'Kecepatan bergerak',
                            icon: Icons.speed_rounded,
                            accentColor: const Color(0xFF10B981),
                            iconBg: const Color(0xFFD1FAE5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 4. RIWAYAT SPLIT KILOMETER (JIKA ADA) ───────────────
              if (widget.splitList.isNotEmpty) ...[
                const SizedBox(height: 14),
                GerakEntrance(
                  delayMs: 180,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Split per Kilometer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (int i = 0; i < widget.splitList.length; i++) ...[
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${widget.splitList[i].kilometerKe}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0077E6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.splitList[i].isTercepat
                                      ? 'Kilometer ${widget.splitList[i].kilometerKe} • Tercepat'
                                      : 'Kilometer ${widget.splitList[i].kilometerKe}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: widget.splitList[i].isTercepat
                                        ? const Color(0xFF0077E6)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                '${widget.splitList[i].paceFormatted} /km',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          if (i < widget.splitList.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child:
                                  Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // ── 5. TOMBOL KEMBALI KE HALAMAN TRACKING & RIWAYAT ───────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/dashboard', (r) => false);
                    }
                  },
                  icon: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Kembali ke Halaman Tracking',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077E6),
                    elevation: 2,
                    shadowColor:
                        const Color(0xFF0077E6).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const RiwayatOlahragaScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFF0077E6),
                    size: 20,
                  ),
                  label: const Text(
                    'Lihat Riwayat Aktivitas',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0077E6),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                        color: Color(0xFFBFDBFE), width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

class _SummaryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subInfo;
  final IconData icon;
  final Color accentColor;
  final Color iconBg;

  const _SummaryMetricTile({
    required this.label,
    required this.value,
    required this.subInfo,
    required this.icon,
    required this.accentColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subInfo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}