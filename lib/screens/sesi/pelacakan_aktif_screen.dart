import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';

import 'ringkasan_sesi_screen.dart';
import 'services/tracking_calculator.dart';
import 'widgets/osm_tracking_map.dart';

class PelacakanAktifScreen extends StatefulWidget {
  final String jenisOlahraga; // 'Berlari' atau 'Berjalan'
  final double targetJarakKm;
  final double userWeightKg;
  final double userHeightCm;

  const PelacakanAktifScreen({
    super.key,
    this.jenisOlahraga = 'Berlari',
    this.targetJarakKm = 5.0,
    this.userWeightKg = 65.0,
    this.userHeightCm = 170.0,
  });

  @override
  State<PelacakanAktifScreen> createState() => _PelacakanAktifScreenState();
}

class _PelacakanAktifScreenState extends State<PelacakanAktifScreen> {
  // ── State Pelacakan ──────────────────────────────────────────────────
  final List<LatLng> _rutePoints = [];
  LatLng? _posisiSaatIni;
  LatLng? _posisiAwal;
  Position? _lastGpsPosition;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _tickerTimer;
  Timer? _simulationTimer;

  int _secondsElapsed = 0;
  bool _isPaused = false;
  bool _followUser = true;

  double _totalDistanceMeters = 0.0;
  int _sensorStepOffset = 0;
  int _stepCount = 0;
  bool _isStepEstimated = true; // Fallback jika sensor hardware tidak tersedia

  double _caloriesBurned = 0.0;
  double _currentSpeedKmh = 0.0;
  double _averageSpeedKmh = 0.0;

  final List<SplitKilometer> _splitList = [];
  int _lastSplitKm = 0;
  Duration _lastSplitDuration = Duration.zero;

  bool _isSimulasiAktif = false;
  String _gpsStatus = "Mencari GPS...";

  @override
  void initState() {
    super.initState();
    _initGpsAndSensors();
    _startTimer();
  }

  // ── Inisialisasi GPS & Sensor Langkah ──────────────────────────────────
  Future<void> _initGpsAndSensors() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _gpsStatus = "GPS mati (Aktifkan GPS)";
        });
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final startCoord = LatLng(initialPos.latitude, initialPos.longitude);
      if (mounted) {
        setState(() {
          _posisiSaatIni = startCoord;
          _posisiAwal = startCoord;
          _rutePoints.add(startCoord);
          _lastGpsPosition = initialPos;
          _gpsStatus = "GPS Siap (±${initialPos.accuracy.toStringAsFixed(0)}m)";
        });
      }
    } catch (_) {
      const fallbackCoord = LatLng(-8.1724, 113.7007);
      if (mounted) {
        setState(() {
          _posisiSaatIni = fallbackCoord;
          _posisiAwal = fallbackCoord;
          _rutePoints.add(fallbackCoord);
          _gpsStatus = "Posisi default aktif";
        });
      }
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!_isPaused && mounted) {
        _onNewGpsPosition(position);
      }
    });

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (!mounted) return;
          if (_sensorStepOffset == 0) {
            _sensorStepOffset = event.steps;
          }
          if (!_isPaused) {
            setState(() {
              _isStepEstimated = false;
              _stepCount = event.steps - _sensorStepOffset;
              if (_stepCount < 0) _stepCount = 0;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isStepEstimated = true;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isStepEstimated = true;
        });
      }
    }
  }

  // ── Penanganan Posisi GPS Baru ─────────────────────────────────────────
  void _onNewGpsPosition(Position pos) {
    if (_lastGpsPosition == null) {
      _lastGpsPosition = pos;
      return;
    }

    final distance = TrackingCalculator.hitungJarakHaversine(
      lat1: _lastGpsPosition!.latitude,
      lon1: _lastGpsPosition!.longitude,
      lat2: pos.latitude,
      lon2: pos.longitude,
    );

    final timeDiffSeconds =
        pos.timestamp.difference(_lastGpsPosition!.timestamp).inMilliseconds /
            1000.0;

    final valid = TrackingCalculator.isTitikValid(
      distanceMeters: distance,
      timeSeconds: timeDiffSeconds > 0 ? timeDiffSeconds : 1.0,
      accuracyMeters: pos.accuracy,
    );

    if (!valid) return;

    final newCoord = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _totalDistanceMeters += distance;
      _rutePoints.add(newCoord);
      _posisiSaatIni = newCoord;
      _lastGpsPosition = pos;

      if (pos.speed > 0) {
        _currentSpeedKmh = pos.speed * 3.6;
      } else if (timeDiffSeconds > 0) {
        _currentSpeedKmh = (distance / timeDiffSeconds) * 3.6;
      }

      _recalculateMetrics();
    });
  }

  // ── Perhitungan Metrik Durasi, Kalori, Pace & Split ─────────────────────
  void _recalculateMetrics() {
    if (_secondsElapsed > 0) {
      final hours = _secondsElapsed / 3600.0;
      _averageSpeedKmh = (_totalDistanceMeters / 1000.0) / hours;
    }

    if (_isStepEstimated) {
      _stepCount = TrackingCalculator.estimasiLangkahDariJarak(
        jarakMeter: _totalDistanceMeters,
        tinggiBadanCm: widget.userHeightCm,
        isBerlari: widget.jenisOlahraga == 'Berlari',
      );
    }

    final durasiMenit = _secondsElapsed / 60.0;
    final met = TrackingCalculator.getMetValue(
      isBerlari: widget.jenisOlahraga == 'Berlari',
      speedKmh: _averageSpeedKmh > 0
          ? _averageSpeedKmh
          : (_currentSpeedKmh > 0 ? _currentSpeedKmh : 4.0),
    );

    _caloriesBurned = TrackingCalculator.hitungKaloriMet(
      met: met,
      beratBadanKg: widget.userWeightKg,
      durasiMenit: durasiMenit,
    );

    final currentKm = (_totalDistanceMeters / 1000.0).floor();
    if (currentKm > _lastSplitKm) {
      for (int km = _lastSplitKm + 1; km <= currentKm; km++) {
        final currentDuration = Duration(seconds: _secondsElapsed);
        final splitDuration = currentDuration - _lastSplitDuration;
        final paceMinutes = splitDuration.inSeconds / 60.0;

        _splitList.add(
          SplitKilometer(
            kilometerKe: km,
            durasiSplit: splitDuration,
            paceFormatted: TrackingCalculator.formatPaceShort(paceMinutes),
          ),
        );
        _lastSplitDuration = currentDuration;
      }
      _lastSplitKm = currentKm;
      _updateFastestSplit();
    }
  }

  void _updateFastestSplit() {
    if (_splitList.isEmpty) return;
    int fastestIdx = 0;
    for (int i = 1; i < _splitList.length; i++) {
      if (_splitList[i].durasiSplit < _splitList[fastestIdx].durasiSplit) {
        fastestIdx = i;
      }
    }
    for (int i = 0; i < _splitList.length; i++) {
      _splitList[i] = SplitKilometer(
        kilometerKe: _splitList[i].kilometerKe,
        durasiSplit: _splitList[i].durasiSplit,
        paceFormatted: _splitList[i].paceFormatted,
        isTercepat: i == fastestIdx,
      );
    }
  }

  // ── Timer Ticker ───────────────────────────────────────────────────────
  void _startTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        setState(() {
          _secondsElapsed++;
          _recalculateMetrics();
        });
      }
    });
  }

  // ── Mode Simulasi Gerak ────────────────────────────────────────────────
  void _toggleSimulasi() {
    setState(() {
      _isSimulasiAktif = !_isSimulasiAktif;
    });

    if (_isSimulasiAktif) {
      _simulationTimer?.cancel();
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (!_isPaused && mounted) {
          final cur = _posisiSaatIni ?? const LatLng(-8.1724, 113.7007);
          final nextLat = cur.latitude + 0.00007;
          final nextLon = cur.longitude + 0.00006;
          final nextPos = LatLng(nextLat, nextLon);

          final distance = TrackingCalculator.hitungJarakHaversine(
            lat1: cur.latitude,
            lon1: cur.longitude,
            lat2: nextLat,
            lon2: nextLon,
          );

          setState(() {
            _totalDistanceMeters += distance;
            _rutePoints.add(nextPos);
            _posisiSaatIni = nextPos;
            _currentSpeedKmh = widget.jenisOlahraga == 'Berlari' ? 9.5 : 4.8;
            _recalculateMetrics();
          });
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulasi pergerakan GPS aktif untuk pengujian rute OpenStreetMap.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _simulationTimer?.cancel();
    }
  }

  // ── Kontrol Jeda, Lanjutkan, Selesai ────────────────────────────────────
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _selesaikanAktivitas() {
    _tickerTimer?.cancel();
    _simulationTimer?.cancel();
    _positionSubscription?.cancel();
    _stepSubscription?.cancel();

    final durasiMenitStr = (_secondsElapsed ~/ 60).toString();
    final durasiFormatted = _formatTimer(_secondsElapsed);
    final jarakKm = (_totalDistanceMeters / 1000.0);
    final jarakFormatted = jarakKm.toStringAsFixed(2).replaceAll('.', ',');

    final avgPaceMin = jarakKm > 0.01 ? (_secondsElapsed / 60.0) / jarakKm : 0.0;
    final paceFormatted = TrackingCalculator.formatPace(avgPaceMin);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RingkasanSesiScreen(
          jenisOlahraga: widget.jenisOlahraga,
          tanggal: 'Hari ini',
          durasiMenit: durasiMenitStr == '0' ? '1' : durasiMenitStr,
          durasiFormatted: durasiFormatted,
          jarakKm: jarakFormatted,
          langkah: _stepCount.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              ),
          isStepEstimated: _isStepEstimated,
          kalori: _caloriesBurned.round().toString(),
          paceRataRata: paceFormatted,
          detakJantung: widget.jenisOlahraga == 'Berlari' ? '138 bpm' : '108 bpm',
          splitList: _splitList,
        ),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _simulationTimer?.cancel();
    _positionSubscription?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jarakKm = _totalDistanceMeters / 1000.0;
    final avgPaceMin = jarakKm > 0.01 ? (_secondsElapsed / 60.0) / jarakKm : 0.0;
    final paceFormatted = TrackingCalculator.formatPace(avgPaceMin);

    return Scaffold(
      backgroundColor: Colors.white,
      // ── Header Bar ──────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_gerak.png',
              height: 28,
              errorBuilder: (_, _, _) => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077E6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.jenisOlahraga,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Badge Status GPS / Simulasi
            GestureDetector(
              onTap: _toggleSimulasi,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isSimulasiAktif ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSimulasiAktif ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSimulasiAktif ? Icons.play_circle_fill_rounded : Icons.gps_fixed_rounded,
                      size: 12,
                      color: _isSimulasiAktif ? const Color(0xFFD97706) : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSimulasiAktif ? 'Demo On' : 'GPS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _isSimulasiAktif ? const Color(0xFFD97706) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Body: Peta OpenStreetMap & Floating Metrics Card ────────────
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // 1. Peta OpenStreetMap
                      Positioned.fill(
                        child: OsmTrackingMap(
                          rutePoints: _rutePoints,
                          posisiSaatIni: _posisiSaatIni,
                          posisiAwal: _posisiAwal,
                          followUser: _followUser,
                          onToggleFollow: () {
                            setState(() {
                              _followUser = !_followUser;
                            });
                          },
                          onExpand: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status GPS: $_gpsStatus • Gunakan tombol +/- pada peta.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),

                      // 2. Kartu Metrik Melayang (Responsif & Anti-Overflow)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Accent Blue Bar
                              Container(
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0077E6),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Timer Durasi Real-Time
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatTimer(_secondsElapsed),
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F2B5C),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'DURASI WAKTU',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // 3 Kolom Indikator Utama: Jarak, Pace, Kalori
                                    Row(
                                      children: [
                                        // 1. Jarak Tempuh
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Jarak',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: jarakKm.toStringAsFixed(2),
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.w900,
                                                          color: Color(0xFF0077E6),
                                                        ),
                                                      ),
                                                      const TextSpan(
                                                        text: ' km',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFF0077E6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // 2. Pace Rata-rata
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Pace Rata-rata',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  paceFormatted,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // 3. Estimasi Kalori MET
                                        Expanded(
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Kalori (MET)',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: _caloriesBurned.round().toString(),
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w900,
                                                          color: Color(0xFFD97706),
                                                        ),
                                                      ),
                                                      const TextSpan(
                                                        text: ' kcal',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFFD97706),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Baris Info: Jumlah Langkah & Kecepatan
                                    Row(
                                      children: [
                                        // Langkah
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF0077E6)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$_stepCount langkah',
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                if (_isStepEstimated)
                                                  const Text(
                                                    ' (Est)',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Kecepatan
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF0077E6)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${_averageSpeedKmh.toStringAsFixed(1)} km/h',
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Action Buttons Row ──────────────────────────────────
              if (!_isPaused) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _togglePause,
                          icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 22),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Jeda',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF233C),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _selesaikanAktivitas,
                          icon: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Selesaikan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003B95),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _togglePause,
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Lanjutkan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF233C),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _selesaikanAktivitas,
                          icon: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Selesai',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003B95),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}