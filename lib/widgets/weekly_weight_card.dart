import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/auth_service.dart';

class WeeklyWeightCard extends StatefulWidget {
  final VoidCallback? onWeightUpdated;

  const WeeklyWeightCard({super.key, this.onWeightUpdated});

  @override
  State<WeeklyWeightCard> createState() => WeeklyWeightCardState();
}

class WeeklyWeightCardState extends State<WeeklyWeightCard> {
  int _weekOffset = 0;
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  bool _showDailyBreakdown = false;
  JsonMap? _weeklyData;

  @override
  void initState() {
    super.initState();
    final nowWeekday = DateTime.now().weekday; // 1 = Senin .. 7 = Minggu
    _selectedDayIndex = (nowWeekday - 1).clamp(0, 6);
    loadWeeklyData();
  }

  Future<void> loadWeeklyData({int? targetOffset}) async {
    if (targetOffset != null) {
      _weekOffset = targetOffset;
    }
    if (mounted) setState(() => _isLoading = true);

    final data = await AuthService.instance
        .fetchWeeklyWeightProgress(weekOffset: _weekOffset);

    if (!mounted) return;

    setState(() {
      _weeklyData = data;
      _isLoading = false;

      if (data != null && data['hari_list'] is List) {
        final days = List<JsonMap>.from(data['hari_list'] as List);
        if (_weekOffset == 0) {
          final todayIdx = days.indexWhere((d) => d['is_today'] == true);
          if (todayIdx != -1) _selectedDayIndex = todayIdx;
        } else {
          final lastLoggedIdx =
              days.lastIndexWhere((d) => d['berat_badan'] != null);
          _selectedDayIndex = lastLoggedIdx != -1 ? lastLoggedIdx : 0;
        }
      }
    });
  }

  String _formatDeltaText(int? gram, String arah, {bool includePrefix = true}) {
    if (arah == 'kosong' || gram == null) return 'Belum dicatat';
    if (arah == 'awal') return 'Berat awal';
    if (gram == 0 || arah == 'tetap') return 'Tetap (0 g)';

    final absGram = gram.abs();
    final kata = gram < 0 ? 'Turun' : 'Naik';
    final prefix = includePrefix ? '$kata ' : (gram < 0 ? '-' : '+');

    if (absGram >= 1000) {
      final kgVal = (absGram / 1000.0).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '$prefix$kgVal kg';
    }
    return '$prefix$absGram g';
  }

  Color _colorForDirection(String arah) {
    switch (arah) {
      case 'turun':
        return const Color(0xFF16A34A); // Hijau
      case 'naik':
        return const Color(0xFFDC2626); // Merah
      default:
        return const Color(0xFF64748B); // Abu-abu
    }
  }

  Color _bgForDirection(String arah) {
    switch (arah) {
      case 'turun':
        return const Color(0xFFDCFCE7);
      case 'naik':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Future<void> _bukaModalCatatBerat({DateTime? initialDate, double? existingBerat}) async {
    final now = DateTime.now();
    DateTime selectedDate = initialDate ?? DateTime(now.year, now.month, now.day);
    final controller = TextEditingController(
      text: existingBerat != null
          ? existingBerat.toStringAsFixed(1)
          : (AuthService.instance.currentUser?.beratBadan?.toStringAsFixed(1) ?? ''),
    );
    bool isSaving = false;

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
                22,
                16,
                22,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catat Berat Badan Harian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jika tanggal sudah tercatat, data lama akan diperbarui tanpa duplikasi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: now.subtract(const Duration(days: 60)),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFF0077E6), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                  .format(selectedDate),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
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
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Berat Badan (kg)',
                      hintText: 'Contoh: 74.5',
                      suffixText: 'kg',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined,
                          color: Color(0xFF0077E6)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final raw =
                                  controller.text.trim().replaceAll(',', '.');
                              final val = double.tryParse(raw);
                              if (val == null || val < 30 || val > 250) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Masukkan berat badan valid antara 30 - 250 kg.'),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final res = await AuthService.instance
                                  .recordDailyWeight(
                                beratBadan: val,
                                tanggal: selectedDate,
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

                              if (res.isSuccess) {
                                await loadWeeklyData();
                                widget.onWeightUpdated?.call();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Text(
                              'Simpan Berat Badan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _bukaRiwayatMingguanModal() {
    final riwayatRaw = _weeklyData?['riwayat_mingguan'];
    if (riwayatRaw is! List || riwayatRaw.isEmpty) return;
    final riwayatList = List<JsonMap>.from(riwayatRaw);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Riwayat Progres Mingguan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih periode Senin – Minggu untuk melihat grafik dan rincian hariannya.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: riwayatList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) {
                      final w = riwayatList[idx];
                      final offset =
                          int.tryParse(w['week_offset']?.toString() ?? '0') ?? 0;
                      final isSelected = offset == _weekOffset;
                      final arah = w['arah']?.toString() ?? 'tetap';
                      final diffGram =
                          int.tryParse(w['perubahan_gram']?.toString() ?? '0') ??
                              0;
                      final wAwal = double.tryParse(
                          w['berat_awal']?.toString() ?? '');
                      final wAkhir = double.tryParse(
                          w['berat_akhir']?.toString() ?? '');
                      final hariDitimbang = int.tryParse(
                              w['hari_ditimbang']?.toString() ?? '0') ??
                          0;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          loadWeeklyData(targetOffset: offset);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          offset == 0
                                              ? 'Minggu Ini'
                                              : '${offset.abs()} Minggu Lalu',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '($hariDitimbang/7 hari)',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      w['label_periode']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    if (wAwal != null && wAkhir != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${wAwal.toStringAsFixed(1)} kg → ${wAkhir.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _bgForDirection(arah),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  hariDitimbang == 0
                                      ? 'Kosong'
                                      : _formatDeltaText(diffGram, arah,
                                          includePrefix: false),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _colorForDirection(arah),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyHistory = _weeklyData?['has_any_history'] == true;
    final periodeLabel = _weeklyData?['periode_label']?.toString() ?? 'Senin – Minggu';
    final beratAwal =
        double.tryParse(_weeklyData?['berat_awal_minggu']?.toString() ?? '');
    final beratAkhir = double.tryParse(
        _weeklyData?['berat_terakhir_minggu']?.toString() ?? '');
    final totalGram =
        int.tryParse(_weeklyData?['total_perubahan_gram']?.toString() ?? '0') ??
            0;
    final arahMingguan =
        _weeklyData?['arah_mingguan']?.toString() ?? 'tetap';
    final jumlahDitimbang = int.tryParse(
            _weeklyData?['jumlah_hari_ditimbang']?.toString() ?? '0') ??
        0;

    final days = (_weeklyData?['hari_list'] is List)
        ? List<JsonMap>.from(_weeklyData!['hari_list'] as List)
        : <JsonMap>[];

    final aktivitasMingguan = (_weeklyData?['aktivitas_mingguan'] is JsonMap)
        ? (_weeklyData!['aktivitas_mingguan'] as JsonMap)
        : <String, dynamic>{};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D5FC9).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HEADER & TOMBOL CATAT BERAT ──────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_weight_rounded,
                  color: Color(0xFF0077E6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progres Berat Badan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Pemantauan harian Senin – Minggu',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _bukaModalCatatBerat(),
                icon: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 17),
                label: const Text(
                  'Catat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077E6),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. NAVIGASI PERIODE MINGGUAN (SENIN - MINGGU) ───────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => loadWeeklyData(targetOffset: _weekOffset - 1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  color: const Color(0xFF0077E6),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Minggu sebelumnya',
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _bukaRiwayatMingguanModal,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekOffset == 0
                                  ? 'Minggu Ini'
                                  : '${_weekOffset.abs()} Minggu Lalu',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0077E6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.history_rounded,
                                size: 14, color: Color(0xFF0077E6)),
                          ],
                        ),
                        Text(
                          periodeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: (_isLoading || _weekOffset >= 0)
                      ? null
                      : () => loadWeeklyData(targetOffset: _weekOffset + 1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  color: _weekOffset >= 0
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF0077E6),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Minggu berikutnya',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!hasAnyHistory && days.every((d) => d['berat_badan'] == null))
            _buildEmptyState()
          else ...[
            // ── 3. RINGKASAN 3 METRIK MINGGUAN ────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    label: 'Awal Minggu',
                    value: beratAwal != null
                        ? '${beratAwal.toStringAsFixed(1)} kg'
                        : '-',
                    subColor: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBox(
                    label: _weekOffset == 0 ? 'Saat Ini' : 'Akhir Minggu',
                    value: beratAkhir != null
                        ? '${beratAkhir.toStringAsFixed(1)} kg'
                        : '-',
                    subColor: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: jumlahDitimbang == 0
                          ? const Color(0xFFF1F5F9)
                          : _bgForDirection(arahMingguan),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Progres 7 Hari',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          jumlahDitimbang == 0
                              ? 'Belum ditimbang'
                              : _formatDeltaText(totalGram, arahMingguan,
                                  includePrefix: false),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: jumlahDitimbang == 0
                                ? const Color(0xFF64748B)
                                : _colorForDirection(arahMingguan),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 4. GRAFIK 7 HARI (SENIN - MINGGU) ─────────────────────
            _buildWeeklyChart(days),

            const SizedBox(height: 14),

            // ── 5. DETAIL HARI TERPILIH & AKTIVITAS PENDUKUNG ─────────
            if (days.isNotEmpty)
              _buildSelectedDayDetail(
                days[_selectedDayIndex.clamp(0, days.length - 1)],
                aktivitasMingguan,
              ),

            const SizedBox(height: 10),

            // ── 6. TOGGLE RINCIAN 7 HARI (GRAM / KG) ──────────────────
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  setState(() => _showDailyBreakdown = !_showDailyBreakdown),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showDailyBreakdown
                          ? 'Sembunyikan rincian harian'
                          : 'Lihat rincian perubahan tiap hari (Sen–Min)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0077E6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showDailyBreakdown
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF0077E6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            if (_showDailyBreakdown) ...[
              const SizedBox(height: 6),
              ...days.map((d) => _buildDailyRowItem(d)),
            ],
          ],

          const SizedBox(height: 12),

          // ── 7. KETERANGAN EDUKASI FLUKTUASI ALAMI ───────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF0284C7), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berat badan dapat berubah secara alami dari hari ke hari. Perubahan berat badan sebaiknya dinilai dari tren beberapa minggu, bukan hanya satu hari.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF0369A1),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.scale_rounded,
              color: Color(0xFF0077E6),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada data penimbangan berat badan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catat berat badanmu secara rutin untuk melihat grafik perkembangan mingguan dari Senin hingga Minggu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _bukaModalCatatBerat(),
            icon: const Icon(Icons.edit_note_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              'Catat Berat Badan Pertama',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<JsonMap> days) {
    final weights = days
        .map((d) => double.tryParse(d['berat_badan']?.toString() ?? ''))
        .toList();
    final directions =
        days.map((d) => d['arah']?.toString() ?? 'kosong').toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 115,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeeklyWeightPainter(
                weights: weights,
                directions: directions,
                selectedIndex: _selectedDayIndex,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(days.length, (idx) {
              final d = days[idx];
              final isSelected = idx == _selectedDayIndex;
              final isToday = d['is_today'] == true;
              final arah = d['arah']?.toString() ?? 'kosong';

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0077E6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          d['hari_pendek']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isToday
                                    ? const Color(0xFF0077E6)
                                    : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : (arah == 'kosong'
                                    ? const Color(0xFFCBD5E1)
                                    : _colorForDirection(arah)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetail(
      JsonMap day, Map<String, dynamic> aktivitasMingguan) {
    final hariLengkap = day['hari_lengkap']?.toString() ?? '';
    final tanggalLabel = day['tanggal_label']?.toString() ?? '';
    final rawDateStr = day['tanggal']?.toString();
    final berat = double.tryParse(day['berat_badan']?.toString() ?? '');
    final selisihGram = int.tryParse(day['selisih_gram']?.toString() ?? '');
    final arah = day['arah']?.toString() ?? 'kosong';
    final isFuture = day['is_future'] == true;

    final act = (day['aktivitas'] is JsonMap)
        ? (day['aktivitas'] as JsonMap)
        : <String, dynamic>{};
    final langkah = int.tryParse(act['langkah']?.toString() ?? '0') ?? 0;
    final jarakKm = double.tryParse(act['jarak_km']?.toString() ?? '0') ?? 0;
    final kalori = double.tryParse(act['kalori']?.toString() ?? '0') ?? 0;
    final durasiMnt =
        int.tryParse(act['durasi_menit']?.toString() ?? '0') ?? 0;

    final hariAktif =
        int.tryParse(aktivitasMingguan['hari_aktif']?.toString() ?? '0') ?? 0;

    return Container(
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
                    Text(
                      '$hariLengkap, $tanggalLabel',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          berat != null
                              ? '${berat.toStringAsFixed(1)} kg'
                              : 'Belum ditimbang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: berat != null
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (berat != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _bgForDirection(arah),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDeltaText(selisihGram, arah),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _colorForDirection(arah),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isFuture)
                TextButton.icon(
                  onPressed: () {
                    final dt = rawDateStr != null
                        ? DateTime.tryParse(rawDateStr)
                        : null;
                    _bukaModalCatatBerat(
                        initialDate: dt, existingBerat: berat);
                  },
                  icon: Icon(
                    berat != null ? Icons.edit_rounded : Icons.add_rounded,
                    size: 16,
                    color: const Color(0xFF0077E6),
                  ),
                  label: Text(
                    berat != null ? 'Ubah' : 'Isi',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0077E6),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Pendukung Hari Ini',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                'Konsistensi: $hariAktif/7 hari aktif',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0077E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniActivityChip(
                  Icons.directions_walk_rounded, '$langkah lkh'),
              const SizedBox(width: 6),
              _buildMiniActivityChip(
                  Icons.route_rounded, '${jarakKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 6),
              _buildMiniActivityChip(Icons.timer_outlined, '$durasiMnt mnt'),
              const SizedBox(width: 6),
              _buildMiniActivityChip(Icons.local_fire_department_rounded,
                  '${kalori.toStringAsFixed(0)} kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActivityChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF0077E6)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRowItem(JsonMap day) {
    final hariLengkap = day['hari_lengkap']?.toString() ?? '';
    final tanggalLabel = day['tanggal_label']?.toString() ?? '';
    final berat = double.tryParse(day['berat_badan']?.toString() ?? '');
    final selisihGram = int.tryParse(day['selisih_gram']?.toString() ?? '');
    final arah = day['arah']?.toString() ?? 'kosong';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              '$hariLengkap ($tanggalLabel)',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Expanded(
            child: Text(
              berat != null ? '${berat.toStringAsFixed(1)} kg' : '-',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: berat != null
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _bgForDirection(arah),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDeltaText(selisihGram, arah),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _colorForDirection(arah),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyWeightPainter extends CustomPainter {
  final List<double?> weights;
  final List<String> directions;
  final int selectedIndex;

  _WeeklyWeightPainter({
    required this.weights,
    required this.directions,
    required this.selectedIndex,
  });

  Color _dotColor(String arah) {
    switch (arah) {
      case 'turun':
        return const Color(0xFF16A34A);
      case 'naik':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (int g = 0; g < 3; g++) {
      final y = 18.0 + ((size.height - 34.0) / 2) * g;
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), gridPaint);
    }

    final validValues = weights.whereType<double>().toList();
    if (validValues.isEmpty) return;

    double minW = validValues.reduce((a, b) => a < b ? a : b);
    double maxW = validValues.reduce((a, b) => a > b ? a : b);
    if ((maxW - minW).abs() < 0.2) {
      minW -= 0.5;
      maxW += 0.5;
    } else {
      final pad = (maxW - minW) * 0.2;
      minW -= pad;
      maxW += pad;
    }

    final colWidth = size.width / 7;
    final topPad = 22.0;
    final bottomPad = 14.0;
    final plotHeight = size.height - topPad - bottomPad;

    final points = <Offset?>[];
    for (int i = 0; i < 7; i++) {
      final w = i < weights.length ? weights[i] : null;
      if (w == null) {
        points.add(null);
      } else {
        final norm = (w - minW) / (maxW - minW);
        final y = topPad + plotHeight * (1.0 - norm);
        final x = colWidth * i + colWidth / 2;
        points.add(Offset(x, y));
      }
    }

    // Gambar garis penghubung antar titik penimbangan yang valid
    final linePaint = Paint()
      ..color = const Color(0xFF0077E6)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    bool started = false;
    for (final pt in points) {
      if (pt != null) {
        if (!started) {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }
    canvas.drawPath(path, linePaint);

    // Gambar titik indikator harian + label angka di atas titik
    for (int i = 0; i < 7; i++) {
      final pt = points[i];
      final xCenter = colWidth * i + colWidth / 2;
      final isSel = i == selectedIndex;

      if (pt == null) {
        final emptyPaint = Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(
          Offset(xCenter, size.height - 14),
          isSel ? 5.0 : 3.5,
          emptyPaint,
        );
        continue;
      }

      final arah = i < directions.length ? directions[i] : 'tetap';
      final color = _dotColor(arah);

      if (isSel) {
        final haloPaint = Paint()
          ..color = color.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 10, haloPaint);
      }

      final whiteBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSel ? 6.5 : 5.2, whiteBorder);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSel ? 4.8 : 3.8, dotPaint);

      final wText = weights[i]!.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(
          text: wText,
          style: TextStyle(
            fontSize: isSel ? 10.5 : 9.5,
            fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
            color: isSel ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyWeightPainter oldDelegate) => true;
}