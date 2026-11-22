import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/riwayat_item.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gerak_animations.dart';
import '../main_navigation_screen.dart';
import '../riwayat/riwayat_olahraga_screen.dart';
import 'ringkasan_sesi_screen.dart';
import 'services/tracking_calculator.dart';
import 'widgets/osm_tracking_map.dart';

class SesiOlahragaScreen extends StatefulWidget {
  final bool showBottomNav;
  const SesiOlahragaScreen({super.key, this.showBottomNav = true});

  @override
  State<SesiOlahragaScreen> createState() => _SesiOlahragaScreenState();
}

class _SesiOlahragaScreenState extends State<SesiOlahragaScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const String _backupKey = 'gerak_active_tracking_backup';

  // ── Pilihan Jenis Aktivitas ──────────────────────────────────────────
  String _jenisAktivitas = 'Berlari'; // 'Berjalan' atau 'Berlari'

  // ── Status Tracking & Timer Wall-Clock Akurat ────────────────────────
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _activeSegmentStart;
  Duration _accumulatedActiveDuration = Duration.zero;
  int _elapsedSeconds = 0;
  Timer? _uiTimer;

  // ── State Peta & GPS ─────────────────────────────────────────────────
  final List<LatLng> _rutePoints = [];
  LatLng? _posisiSaatIni;
  LatLng? _posisiAwal;
  Position? _lastValidPosition;
  bool _followUser = true;

  bool _isGpsLoading = true;
  bool _gpsServiceEnabled = true;
  LocationPermission _locationPermission = LocationPermission.whileInUse;
  String _gpsStatusText = 'Mencari sinyal GPS...';

  StreamSubscription<Position>? _positionSub;

  // ── Metrik Aktivitas Real-Time ───────────────────────────────────────
  double _totalDistanceMeters = 0.0;
  double _currentSpeedKmh = 0.0;
  double _averageSpeedKmh = 0.0;
  double _caloriesBurned = 0.0;

  // Sensor Langkah Hardware
  StreamSubscription<StepCount>? _stepSub;
  bool _sensorLangkahTersedia = false;
  int? _stepBaseline;
  int _stepCount = 0;

  // Split Kilometer & Series Kecepatan
  final List<SplitKilometer> _splitList = [];
  final List<double> _speedSamples = [];
  int _lastSplitKm = 0;
  Duration _lastSplitDuration = Duration.zero;

  late final AnimationController _livePulseController;

  double get _userWeightKg =>
      AuthService.instance.currentUser?.beratBadan ?? 65.0;

  bool get _isBerlari => _jenisAktivitas == 'Berlari';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    RiwayatService.instance.initialize();
    _initInitialGps();
    _restoreBackupIfAny();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTimer?.cancel();
    _positionSub?.cancel();
    _stepSub?.cancel();
    _livePulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTracking) {
      _syncElapsedFromWallClock();
      _persistActiveBackup();
    } else if (state == AppLifecycleState.paused && _isTracking) {
      _persistActiveBackup();
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // 1. GPS & PERMISSION HANDLER
  // ═════════════════════════════════════════════════════════════════════

  Future<bool> _ensureLocationReady({bool requestIfNeeded = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _gpsServiceEnabled = false;
          _isGpsLoading = false;
          _gpsStatusText = 'GPS mati • Aktifkan lokasi';
        });
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfNeeded) {
      permission = await Geolocator.requestPermission();
    }

    if (mounted) {
      setState(() {
        _gpsServiceEnabled = true;
        _locationPermission = permission;
      });
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isGpsLoading = false;
          _gpsStatusText = permission == LocationPermission.deniedForever
              ? 'Izin lokasi diblokir'
              : 'Izin lokasi diperlukan';
        });
      }
      return false;
    }

    return true;
  }

  Future<void> _initInitialGps() async {
    if (mounted) {
      setState(() {
        _isGpsLoading = true;
        _gpsStatusText = 'Mencari sinyal GPS...';
      });
    }

    final ready = await _ensureLocationReady(requestIfNeeded: true);
    if (!ready) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final coord = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _posisiSaatIni = coord;
        if (!_isTracking) {
          _posisiAwal = coord;
        }
        _isGpsLoading = false;
        _gpsStatusText = 'GPS Siap • ±${pos.accuracy.round()}m';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isGpsLoading = false;
        _gpsStatusText = 'Menunggu sinyal satelit GPS';
      });
    }
  }

  void _startGpsStream() {
    _positionSub?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
      (Position pos) {
        if (!mounted) return;
        final coord = LatLng(pos.latitude, pos.longitude);

        setState(() {
          _isGpsLoading = false;
          _gpsStatusText = 'GPS Aktif • ±${pos.accuracy.round()}m';
          _posisiSaatIni = coord;
        });

        if (!_isTracking || _isPaused) return;

        if (_lastValidPosition == null) {
          setState(() {
            _lastValidPosition = pos;
            _posisiAwal ??= coord;
            if (_rutePoints.isEmpty) {
              _rutePoints.add(coord);
            }
          });
          return;
        }

        final distance = TrackingCalculator.hitungJarakHaversine(
          lat1: _lastValidPosition!.latitude,
          lon1: _lastValidPosition!.longitude,
          lat2: pos.latitude,
          lon2: pos.longitude,
        );

        final dtSeconds = pos.timestamp
                .difference(_lastValidPosition!.timestamp)
                .inMilliseconds /
            1000.0;

        final valid = TrackingCalculator.isTitikValid(
          distanceMeters: distance,
          timeSeconds: dtSeconds > 0 ? dtSeconds : 1.0,
          accuracyMeters: pos.accuracy,
          isBerlari: _isBerlari,
        );

        if (!valid) return;

        setState(() {
          _totalDistanceMeters += distance;
          _rutePoints.add(coord);
          _lastValidPosition = pos;

          if (pos.speed > 0.2) {
            _currentSpeedKmh = pos.speed * 3.6;
          } else if (dtSeconds > 0) {
            _currentSpeedKmh = (distance / dtSeconds) * 3.6;
          }

          if (_speedSamples.length < 60) {
            _speedSamples.add(
              double.parse(_currentSpeedKmh.toStringAsFixed(1)),
            );
          }

          _recalculateMetrics();
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _gpsStatusText = 'Sinyal GPS terganggu';
        });
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 2. SENSOR LANGKAH (HARDWARE PEDOMETER ONLY)
  // ═════════════════════════════════════════════════════════════════════

  void _startStepSensor() {
    _stepSub?.cancel();
    _stepBaseline = null;

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (!mounted) return;
          _stepBaseline ??= event.steps - _stepCount;
          if (!_isPaused) {
            final computed = event.steps - (_stepBaseline ?? event.steps);
            setState(() {
              _sensorLangkahTersedia = true;
              _stepCount = computed >= 0 ? computed : 0;
            });
          } else {
            // Saat jeda, geser baseline agar langkah selama jeda tidak ikut dihitung
            _stepBaseline = event.steps - _stepCount;
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _sensorLangkahTersedia = false;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _sensorLangkahTersedia = false;
        });
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // 3. KONTROL MULAI, PAUSE, RESUME & SELESAI
  // ═════════════════════════════════════════════════════════════════════

  Future<void> _mulaiAktivitas() async {
    HapticFeedback.mediumImpact();

    final gpsReady = await _ensureLocationReady(requestIfNeeded: true);
    if (!gpsReady) {
      if (!mounted) return;
      _showGpsRequiredDialog();
      return;
    }

    if (_posisiSaatIni == null) {
      await _initInitialGps();
    }

    final startCoord = _posisiSaatIni;
    final now = DateTime.now();

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _activeSegmentStart = now;
      _accumulatedActiveDuration = Duration.zero;
      _elapsedSeconds = 0;

      _totalDistanceMeters = 0.0;
      _currentSpeedKmh = 0.0;
      _averageSpeedKmh = 0.0;
      _caloriesBurned = 0.0;

      _stepCount = 0;
      _stepBaseline = null;

      _splitList.clear();
      _speedSamples.clear();
      _lastSplitKm = 0;
      _lastSplitDuration = Duration.zero;

      _rutePoints.clear();
      _lastValidPosition = null;
      if (startCoord != null) {
        _posisiAwal = startCoord;
        _rutePoints.add(startCoord);
      }
      _followUser = true;
    });

    _startTicker();
    _startGpsStream();
    _startStepSensor();
    await _persistActiveBackup();
  }

  void _pauseAktivitas() {
    if (!_isTracking || _isPaused) return;
    HapticFeedback.lightImpact();

    if (_activeSegmentStart != null) {
      _accumulatedActiveDuration +=
          DateTime.now().difference(_activeSegmentStart!);
      _activeSegmentStart = null;
    }

    setState(() {
      _isPaused = true;
      _currentSpeedKmh = 0.0;
      _elapsedSeconds = _accumulatedActiveDuration.inSeconds;
    });

    _persistActiveBackup();
  }

  void _resumeAktivitas() {
    if (!_isTracking || !_isPaused) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isPaused = false;
      _activeSegmentStart = DateTime.now();
      _lastValidPosition = null;
    });

    _persistActiveBackup();
  }

  Future<void> _konfirmasiSelesai() async {
    HapticFeedback.mediumImpact();

    final wasPaused = _isPaused;
    if (!wasPaused) {
      _pauseAktivitas();
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_score_rounded,
                color: Color(0xFF0077E6),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Selesaikan Aktivitas?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Pastikan sesi $_jenisAktivitas kamu sudah selesai. Hasil tracking akan disimpan ke riwayat dan statistik progresmu.',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Lanjutkan Latihan',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
            child: const Text(
              'Ya, Selesai',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) {
      if (!wasPaused && mounted) {
        _resumeAktivitas();
      }
      return;
    }

    await _selesaikanDanSimpan();
  }

  Future<void> _selesaikanDanSimpan() async {
    _uiTimer?.cancel();
    _positionSub?.cancel();
    _stepSub?.cancel();
    await _clearActiveBackup();

    final totalSeconds = _elapsedSeconds > 0 ? _elapsedSeconds : 1;
    final jarakKm = _totalDistanceMeters / 1000.0;
    final avgPaceMin =
        jarakKm > 0.01 ? (totalSeconds / 60.0) / jarakKm : 0.0;
    final paceFormatted = TrackingCalculator.formatPace(avgPaceMin);
    final avgSpeed = jarakKm > 0 ? (jarakKm / (totalSeconds / 3600.0)) : 0.0;

    final durasiMenit = (totalSeconds / 60.0).ceil().clamp(1, 9999);
    final durasiFormatted = TrackingCalculator.formatDurasiHms(totalSeconds);
    final ruteCopy = List<LatLng>.from(_rutePoints);
    final jenisCopy = _jenisAktivitas;
    final langkahCopy = _sensorLangkahTersedia ? _stepCount : 0;
    final sensorTersediaCopy = _sensorLangkahTersedia;
    final kaloriCopy = _caloriesBurned;
    final splitsCopy = List<SplitKilometer>.from(_splitList);
    final speedSeriesCopy = _speedSamples.isNotEmpty
        ? List<double>.from(_speedSamples)
        : <double>[
            double.parse((avgSpeed * 0.85).toStringAsFixed(1)),
            double.parse(avgSpeed.toStringAsFixed(1)),
            double.parse((avgSpeed * 0.95).toStringAsFixed(1)),
          ];

    final itemBaru = RiwayatItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jenis: jenisCopy,
      tanggal: DateTime.now(),
      jarakKm: double.parse(jarakKm.toStringAsFixed(2)),
      kalori: kaloriCopy.round(),
      waktuMenit: durasiMenit,
      durasiDetik: totalSeconds,
      langkah: langkahCopy,
      sensorLangkahTersedia: sensorTersediaCopy,
      paceRataRata: paceFormatted,
      kecepatanRataRataKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      kecepatanSeries: speedSeriesCopy,
      rutePoints: ruteCopy,
    );

    await RiwayatService.instance.tambahAktivitas(itemBaru);
    final syncResult = await AuthService.instance.simpanAktivitasKeServer(
      jenisOlahraga: jenisCopy,
      jarakKm: double.parse(jarakKm.toStringAsFixed(3)),
      durasiDetik: totalSeconds,
      jumlahLangkah: langkahCopy,
      kaloriTerbakar: double.parse(kaloriCopy.toStringAsFixed(1)),
    );

    if (!mounted) return;

    setState(() {
      _isTracking = false;
      _isPaused = false;
      _activeSegmentStart = null;
      _accumulatedActiveDuration = Duration.zero;
      _elapsedSeconds = 0;
      _totalDistanceMeters = 0.0;
      _currentSpeedKmh = 0.0;
      _averageSpeedKmh = 0.0;
      _caloriesBurned = 0.0;
      _stepCount = 0;
      _rutePoints.clear();
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, _, _) => RingkasanSesiScreen(
          jenisOlahraga: jenisCopy,
          tanggal: 'Hari ini',
          durasiMenit: durasiMenit.toString(),
          durasiFormatted: durasiFormatted,
          jarakKm: jarakKm.toStringAsFixed(2).replaceAll('.', ','),
          jarakMeter: _totalDistanceMeters,
          langkah: sensorTersediaCopy
              ? langkahCopy.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]}.',
                  )
              : 'Tidak tersedia',
          sensorLangkahTersedia: sensorTersediaCopy,
          isStepEstimated: false,
          kalori: kaloriCopy.round().toString(),
          paceRataRata: paceFormatted,
          kecepatanRataRataKmh: avgSpeed,
          splitList: splitsCopy,
          kecepatanSeries: speedSeriesCopy,
          rutePoints: ruteCopy,
          syncMessage: syncResult.message,
          isSynced: syncResult.isSuccess,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 4. TIMER, METRIK & BACKUP SESI
  // ═════════════════════════════════════════════════════════════════════

  void _startTicker() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isTracking || _isPaused || !mounted) return;
      _syncElapsedFromWallClock();
      if (_elapsedSeconds % 10 == 0) {
        _persistActiveBackup();
      }
    });
  }

  void _syncElapsedFromWallClock() {
    if (!_isTracking) return;
    final activeExtra = (!_isPaused && _activeSegmentStart != null)
        ? DateTime.now().difference(_activeSegmentStart!)
        : Duration.zero;
    final total = _accumulatedActiveDuration + activeExtra;

    setState(() {
      _elapsedSeconds = total.inSeconds;
      _recalculateMetrics();
    });
  }

  void _recalculateMetrics() {
    if (_elapsedSeconds > 0) {
      final hours = _elapsedSeconds / 3600.0;
      _averageSpeedKmh = (_totalDistanceMeters / 1000.0) / hours;
    }

    final durasiMenit = _elapsedSeconds / 60.0;
    final effectiveSpeed = _averageSpeedKmh > 0.2
        ? _averageSpeedKmh
        : (_currentSpeedKmh > 0.2 ? _currentSpeedKmh : (_isBerlari ? 7.5 : 4.2));

    final met = TrackingCalculator.getMetValue(
      isBerlari: _isBerlari,
      speedKmh: effectiveSpeed,
    );

    _caloriesBurned = TrackingCalculator.hitungKaloriMet(
      met: met,
      beratBadanKg: _userWeightKg,
      durasiMenit: durasiMenit,
    );

    final currentKm = (_totalDistanceMeters / 1000.0).floor();
    if (currentKm > _lastSplitKm) {
      for (int km = _lastSplitKm + 1; km <= currentKm; km++) {
        final currentDuration = Duration(seconds: _elapsedSeconds);
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

  Future<void> _persistActiveBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'jenis': _jenisAktivitas,
        'elapsedSeconds': _elapsedSeconds,
        'distanceMeters': _totalDistanceMeters,
        'stepCount': _stepCount,
        'calories': _caloriesBurned,
        'rutePoints': _rutePoints
            .map((p) => {'lat': p.latitude, 'lon': p.longitude})
            .toList(),
      };
      await prefs.setString(_backupKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _clearActiveBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backupKey);
    } catch (_) {}
  }

  Future<void> _restoreBackupIfAny() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_backupKey);
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final savedSeconds = (data['elapsedSeconds'] as num?)?.toInt() ?? 0;
      if (savedSeconds < 5) {
        await _clearActiveBackup();
        return;
      }

      if (!mounted) return;
      final pts = (data['rutePoints'] as List<dynamic>? ?? [])
          .whereType()
          .map((m) => LatLng(
                (m['lat'] as num).toDouble(),
                (m['lon'] as num).toDouble(),
              ))
          .toList();

      setState(() {
        _jenisAktivitas = (data['jenis'] ?? 'Berlari').toString();
        _isTracking = true;
        _isPaused = true;
        _accumulatedActiveDuration = Duration(seconds: savedSeconds);
        _elapsedSeconds = savedSeconds;
        _totalDistanceMeters =
            (data['distanceMeters'] as num?)?.toDouble() ?? 0.0;
        _stepCount = (data['stepCount'] as num?)?.toInt() ?? 0;
        _caloriesBurned = (data['calories'] as num?)?.toDouble() ?? 0.0;
        _rutePoints
          ..clear()
          ..addAll(pts);
        if (pts.isNotEmpty) {
          _posisiAwal = pts.first;
          _posisiSaatIni = pts.last;
        }
      });
      _startTicker();
      _startGpsStream();
    } catch (_) {}
  }

  void _showGpsRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Akses Lokasi Diperlukan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          !_gpsServiceEnabled
              ? 'Layanan GPS pada perangkatmu sedang nonaktif. Aktifkan GPS untuk mulai melacak rute perjalanan.'
              : 'GERAK membutuhkan izin lokasi untuk merekam rute dan menghitung jarak lari/jalan secara akurat.',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!_gpsServiceEnabled) {
                await Geolocator.openLocationSettings();
              } else if (_locationPermission ==
                  LocationPermission.deniedForever) {
                await Geolocator.openAppSettings();
              } else {
                await _initInitialGps();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077E6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Buka Pengaturan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // 5. BUILD UI MODERN FITNESS TRACKING
  // ═════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final jarakAdaptif =
        TrackingCalculator.formatJarakAdaptif(_totalDistanceMeters);
    final jarakKm = _totalDistanceMeters / 1000.0;
    final avgPaceMin =
        jarakKm > 0.01 ? (_elapsedSeconds / 60.0) / jarakKm : 0.0;
    final paceFormatted = TrackingCalculator.formatPace(avgPaceMin);
    final speedToShow = _isTracking && !_isPaused && _currentSpeedKmh > 0.3
        ? _currentSpeedKmh
        : _averageSpeedKmh;

    final gpsColor = !_gpsServiceEnabled ||
            _locationPermission == LocationPermission.denied ||
            _locationPermission == LocationPermission.deniedForever
        ? const Color(0xFFDC2626)
        : (_isGpsLoading
            ? const Color(0xFFF59E0B)
            : const Color(0xFF059669));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // ── A. HEADER RINGKAS & MODERN ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final nav = MainNavigationController.of(context);
                        if (nav != null) {
                          nav.switchTab(0);
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .pushReplacementNamed('/dashboard');
                        }
                      },
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Tracking Aktivitas',
                              style: TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isBerlari
                                    ? Icons.directions_run_rounded
                                    : Icons.directions_walk_rounded,
                                color: const Color(0xFF0077E6),
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _isTracking
                              ? (_isPaused
                                  ? 'Sesi dijeda — tekan Lanjutkan saat siap'
                                  : 'Tetap fokus, setiap langkahmu tercatat!')
                              : 'Siap bergerak hari ini? Pilih aktivitasmu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RiwayatOlahragaScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded,
                                color: Color(0xFF0077E6), size: 17),
                            SizedBox(width: 4),
                            Text(
                              'Riwayat',
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
                  ),
                ],
              ),
            ),

            // ── KONTEN SCROLLABLE ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
                children: [
                  if (_isTracking) ...[
                    _buildLiveStatusBanner(),
                    const SizedBox(height: 12),
                  ],

                  // ── B. PILIHAN JENIS AKTIVITAS ───────────────────────
                  GerakEntrance(
                    delayMs: 30,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActivityTypeCard(
                            title: 'Berjalan Kaki',
                            subtitle: 'Santai & ritme stabil',
                            icon: Icons.directions_walk_rounded,
                            selected: _jenisAktivitas == 'Berjalan',
                            disabled: _isTracking,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _jenisAktivitas = 'Berjalan');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActivityTypeCard(
                            title: 'Berlari',
                            subtitle: 'Kardio & pembakaran optimal',
                            icon: Icons.directions_run_rounded,
                            selected: _jenisAktivitas == 'Berlari',
                            disabled: _isTracking,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _jenisAktivitas = 'Berlari');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── C. AREA PETA OPENSTREETMAP UTAMA ─────────────────
                  GerakEntrance(
                    delayMs: 70,
                    child: Container(
                      height: _isTracking ? 245 : 230,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: OsmTrackingMap(
                        rutePoints: _rutePoints,
                        posisiSaatIni: _posisiSaatIni,
                        posisiAwal: _posisiAwal,
                        followUser: _followUser,
                        isTrackingActive: _isTracking && !_isPaused,
                        isGpsLoading: _isGpsLoading,
                        gpsStatusText: _gpsStatusText,
                        gpsStatusColor: gpsColor,
                        onToggleFollow: () {
                          setState(() => _followUser = true);
                        },
                        onGpsActionTap: (!_gpsServiceEnabled ||
                                _locationPermission ==
                                    LocationPermission.denied ||
                                _locationPermission ==
                                    LocationPermission.deniedForever)
                            ? () async {
                                if (!_gpsServiceEnabled) {
                                  await Geolocator.openLocationSettings();
                                } else {
                                  await _initInitialGps();
                                }
                              }
                            : null,
                        gpsActionLabel:
                            !_gpsServiceEnabled ? 'Aktifkan' : 'Izinkan',
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── D. INFORMASI AKTIVITAS (DURASI & GRID METRIK) ────
                  GerakEntrance(
                    delayMs: 110,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0077E6)
                                    .withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.timer_rounded,
                                  color: Color(0xFF0077E6),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DURASI AKTIVITAS',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      TrackingCalculator.formatDurasiHms(
                                          _elapsedSeconds),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isTracking
                                      ? (_isPaused
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFDBEAFE))
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _isTracking
                                      ? (_isPaused ? 'Jeda' : 'Aktif')
                                      : 'Siap',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: _isTracking
                                        ? (_isPaused
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF0077E6))
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricGridCard(
                                label: 'Jarak Tempuh',
                                value: jarakAdaptif.nilai,
                                unit: jarakAdaptif.satuan,
                                subInfo: jarakKm >= 1.0
                                    ? '${_totalDistanceMeters.round()} meter'
                                    : 'Satuan meter',
                                icon: Icons.route_rounded,
                                accentColor: const Color(0xFF0077E6),
                                iconBg: const Color(0xFFDBEAFE),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricGridCard(
                                label: _isBerlari ? 'Pace Lari' : 'Kecepatan',
                                value: _isBerlari
                                    ? paceFormatted.replaceAll(' /km', '')
                                    : speedToShow.toStringAsFixed(1),
                                unit: _isBerlari ? '/km' : 'km/jam',
                                subInfo: _isBerlari
                                    ? '${speedToShow.toStringAsFixed(1)} km/jam'
                                    : 'Pace ${paceFormatted.replaceAll(' /km', '')}/km',
                                icon: Icons.speed_rounded,
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
                              child: _MetricGridCard(
                                label: 'Jumlah Langkah',
                                value: _sensorLangkahTersedia
                                    ? _stepCount.toString()
                                    : 'N/A',
                                unit: _sensorLangkahTersedia ? 'langkah' : '',
                                subInfo: _sensorLangkahTersedia
                                    ? 'Sensor perangkat aktif'
                                    : 'Sensor belum tersedia',
                                icon: Icons.do_not_step_rounded,
                                accentColor: const Color(0xFF0EA5E9),
                                iconBg: const Color(0xFFE0F2FE),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricGridCard(
                                label: 'Kalori Terbakar',
                                value: _caloriesBurned.round().toString(),
                                unit: 'kcal',
                                subInfo:
                                    'Estimasi (${_userWeightKg.round()} kg)',
                                icon: Icons.local_fire_department_rounded,
                                accentColor: const Color(0xFFF59E0B),
                                iconBg: const Color(0xFFFEF3C7),
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

            // ── E. TOMBOL AKSI UTAMA (MULAI / PAUSE / RESUME / SELESAI) ──
            Container(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              color: const Color(0xFFF7FAFF),
              child: _buildActionControls(),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNavBar(currentIndex: 2) : null,
    );
  }

  Widget _buildLiveStatusBanner() {
    final isPaused = _isPaused;
    final bgColor =
        isPaused ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF);
    final borderColor =
        isPaused ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE);
    final dotColor =
        isPaused ? const Color(0xFFD97706) : const Color(0xFF0077E6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _livePulseController,
            builder: (_, _) => Opacity(
              opacity: isPaused ? 1.0 : (0.45 + _livePulseController.value * 0.55),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPaused
                  ? 'Aktivitas Dijeda • Perekaman sementara dihentikan'
                  : 'Tracking Berlangsung • Merecord rute $_jenisAktivitas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: dotColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls() {
    if (!_isTracking) {
      return _StartTrackingButton(
        jenisAktivitas: _jenisAktivitas,
        onPressed: _mulaiAktivitas,
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isPaused ? _resumeAktivitas : _pauseAktivitas,
              icon: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: 23,
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
                elevation: 2,
                shadowColor: (_isPaused
                        ? const Color(0xFF0077E6)
                        : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.35),
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
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _konfirmasiSelesai,
              icon: const Icon(
                Icons.stop_circle_outlined,
                color: Colors.white,
                size: 21,
              ),
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
                elevation: 2,
                shadowColor: const Color(0xFF0F2B5C).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _ActivityTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0077E6) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF0077E6).withValues(alpha: 0.28)
                  : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF0077E6),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

class _MetricGridCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String subInfo;
  final IconData icon;
  final Color accentColor;
  final Color iconBg;

  const _MetricGridCard({
    required this.label,
    required this.value,
    required this.unit,
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
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                ],
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

class _StartTrackingButton extends StatefulWidget {
  final String jenisAktivitas;
  final VoidCallback onPressed;

  const _StartTrackingButton({
    required this.jenisAktivitas,
    required this.onPressed,
  });

  @override
  State<_StartTrackingButton> createState() => _StartTrackingButtonState();
}

class _StartTrackingButtonState extends State<_StartTrackingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0077E6), Color(0xFF005BB5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0077E6).withValues(alpha: 0.36),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Mulai Aktivitas ${widget.jenisAktivitas}',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}