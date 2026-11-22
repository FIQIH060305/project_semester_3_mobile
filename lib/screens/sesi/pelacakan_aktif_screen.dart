import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';

import '../../services/auth_service.dart';
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
  final List<LatLng> _rutePoints = [];
  LatLng? _posisiSaatIni;
  LatLng? _posisiAwal;
  Position? _lastGpsPosition;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _tickerTimer;

  DateTime? _segmentStart;
  Duration _accumulatedDuration = Duration.zero;
  int _secondsElapsed = 0;
  bool _isPaused = false;
  bool _followUser = true;

  double _totalDistanceMeters = 0.0;
  int? _sensorStepOffset;
  int _stepCount = 0;
  bool _sensorLangkahTersedia = false;

  double _caloriesBurned = 0.0;
  double _currentSpeedKmh = 0.0;
  double _averageSpeedKmh = 0.0;

  final List<SplitKilometer> _splitList = [];
  final List<double> _speedSeries = [];
  int _lastSplitKm = 0;
  Duration _lastSplitDuration = Duration.zero;

  String _gpsStatus = "Mencari GPS...";

  double get _effectiveWeightKg =>
      AuthService.instance.currentUser?.beratBadan ?? widget.userWeightKg;

  @override
  void initState() {
    super.initState();
    _segmentStart = DateTime.now();
    _initGpsAndSensors();
    _startTimer();
  }

  Future<void> _initGpsAndSensors() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      setState(() => _gpsStatus = "GPS mati (Aktifkan GPS)");
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      final initialPos = await Geolocator.getCurrentPosition(
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
          _gpsStatus = "GPS Siap • ±${initialPos.accuracy.round()}m";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _gpsStatus = "Menunggu sinyal GPS...");
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
          _sensorStepOffset ??= event.steps - _stepCount;
          if (!_isPaused) {
            setState(() {
              _sensorLangkahTersedia = true;
              final val = event.steps - (_sensorStepOffset ?? event.steps);
              _stepCount = val >= 0 ? val : 0;
            });
          } else {
            _sensorStepOffset = event.steps - _stepCount;
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _sensorLangkahTersedia = false);
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _sensorLangkahTersedia = false);
      }
    }
  }

  void _onNewGpsPosition(Position pos) {
    final coord = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _posisiSaatIni = coord;
      _gpsStatus = "GPS Aktif • ±${pos.accuracy.round()}m";
    });

    if (_lastGpsPosition == null) {
      _lastGpsPosition = pos;
      _posisiAwal ??= coord;
      if (_rutePoints.isEmpty) _rutePoints.add(coord);
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
      isBerlari: widget.jenisOlahraga == 'Berlari',
    );

    if (!valid) return;

    setState(() {
      _totalDistanceMeters += distance;
      _rutePoints.add(coord);
      _lastGpsPosition = pos;

      if (pos.speed > 0.2) {
        _currentSpeedKmh = pos.speed * 3.6;
      } else if (timeDiffSeconds > 0) {
        _currentSpeedKmh = (distance / timeDiffSeconds) * 3.6;
      }

      if (_speedSeries.length < 60) {
        _speedSeries.add(double.parse(_currentSpeedKmh.toStringAsFixed(1)));
      }

      _recalculateMetrics();
    });
  }

  void _recalculateMetrics() {
    if (_secondsElapsed > 0) {
      final hours = _secondsElapsed / 3600.0;
      _averageSpeedKmh = (_totalDistanceMeters / 1000.0) / hours;
    }

    final durasiMenit = _secondsElapsed / 60.0;
    final met = TrackingCalculator.getMetValue(
      isBerlari: widget.jenisOlahraga == 'Berlari',
      speedKmh: _averageSpeedKmh > 0.2
          ? _averageSpeedKmh
          : (_currentSpeedKmh > 0.2 ? _currentSpeedKmh : 4.2),
    );

    _caloriesBurned = TrackingCalculator.hitungKaloriMet(
      met: met,
      beratBadanKg: _effectiveWeightKg,
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
    }
  }

  void _startTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        final extra = _segmentStart != null
            ? DateTime.now().difference(_segmentStart!)
            : Duration.zero;
        setState(() {
          _secondsElapsed = (_accumulatedDuration + extra).inSeconds;
          _recalculateMetrics();
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (!_isPaused) {
        if (_segmentStart != null) {
          _accumulatedDuration += DateTime.now().difference(_segmentStart!);
          _segmentStart = null;
        }
        _isPaused = true;
      } else {
        _segmentStart = DateTime.now();
        _lastGpsPosition = null;
        _isPaused = false;
      }
    });
  }

  void _selesaikanAktivitas() {
    _tickerTimer?.cancel();
    _positionSubscription?.cancel();
    _stepSubscription?.cancel();

    final durasiMenitStr = (_secondsElapsed / 60.0).ceil().clamp(1, 9999).toString();
    final durasiFormatted = TrackingCalculator.formatDurasiHms(_secondsElapsed);
    final jarakKm = _totalDistanceMeters / 1000.0;
    final jarakFormatted = jarakKm.toStringAsFixed(2).replaceAll('.', ',');

    final avgPaceMin = jarakKm > 0.01 ? (_secondsElapsed / 60.0) / jarakKm : 0.0;
    final paceFormatted = TrackingCalculator.formatPace(avgPaceMin);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RingkasanSesiScreen(
          jenisOlahraga: widget.jenisOlahraga,
          tanggal: 'Hari ini',
          durasiMenit: durasiMenitStr,
          durasiFormatted: durasiFormatted,
          jarakKm: jarakFormatted,
          jarakMeter: _totalDistanceMeters,
          langkah: _sensorLangkahTersedia
              ? _stepCount.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]}.',
                  )
              : 'Tidak tersedia',
          sensorLangkahTersedia: _sensorLangkahTersedia,
          isStepEstimated: false,
          kalori: _caloriesBurned.round().toString(),
          paceRataRata: paceFormatted,
          kecepatanRataRataKmh: _averageSpeedKmh,
          splitList: _splitList,
          kecepatanSeries: _speedSeries,
          rutePoints: List<LatLng>.from(_rutePoints),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _positionSubscription?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jarakAdaptif =
        TrackingCalculator.formatJarakAdaptif(_totalDistanceMeters);
    final jarakKm = _totalDistanceMeters / 1000.0;
    final avgPaceMin = jarakKm > 0.01 ? (_secondsElapsed / 60.0) / jarakKm : 0.0;
    final paceFormatted = TrackingCalculator.formatPace(avgPaceMin);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Tracking • ${widget.jenisOlahraga}',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OsmTrackingMap(
                        rutePoints: _rutePoints,
                        posisiSaatIni: _posisiSaatIni,
                        posisiAwal: _posisiAwal,
                        followUser: _followUser,
                        gpsStatusText: _gpsStatus,
                        onToggleFollow: () {
                          setState(() => _followUser = !_followUser);
                        },
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TrackingCalculator.formatDurasiHms(
                                  _secondsElapsed),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _miniMetric('Jarak',
                                    '${jarakAdaptif.nilai} ${jarakAdaptif.satuan}'),
                                _miniMetric('Pace', paceFormatted),
                                _miniMetric('Kalori (Est)',
                                    '${_caloriesBurned.round()} kcal'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _togglePause,
                        icon: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          _isPaused ? 'Resume' : 'Pause',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPaused
                              ? const Color(0xFF0077E6)
                              : const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _selesaikanAktivitas,
                        icon: const Icon(Icons.stop_circle_outlined,
                            color: Colors.white),
                        label: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2B5C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0077E6),
          ),
        ),
      ],
    );
  }
}