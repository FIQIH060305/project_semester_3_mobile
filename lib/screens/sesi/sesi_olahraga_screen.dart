import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/riwayat_item.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../main_navigation_screen.dart';
import '../riwayat/riwayat_olahraga_screen.dart';
import 'ringkasan_sesi_screen.dart';
import 'services/tracking_calculator.dart';
import 'widgets/osm_tracking_map.dart';

/// Controller global untuk menyinkronkan status sesi aktif dengan navigasi utama
/// sehingga Bottom Navigation Bar hilang otomatis saat persiapan & sesi berlangsung.
class TrackingSessionController {
  TrackingSessionController._();
  static final ValueNotifier<bool> isSessionActive = ValueNotifier<bool>(false);
  static VoidCallback? onBackPressedDuringSession;
}

class SesiOlahragaScreen extends StatefulWidget {
  final bool showBottomNav;
  const SesiOlahragaScreen({super.key, this.showBottomNav = true});

  @override
  State<SesiOlahragaScreen> createState() => _SesiOlahragaScreenState();
}

class _SesiOlahragaScreenState extends State<SesiOlahragaScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const String _backupKey = 'gerak_active_tracking_backup';
  static const int _durasiPersiapanDetik = 30;

  // ── Pilihan Jenis Aktivitas ──────────────────────────────────────────
  String _jenisAktivitas = 'Berlari'; // 'Berjalan' atau 'Berlari'

  // ── Status Persiapan 30 Detik ────────────────────────────────────────
  bool _isPreparing = false;
  int _prepSecondsRemaining = _durasiPersiapanDetik;
  Timer? _prepTimer;

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

  // Sensor Langkah & Estimasi Langkah
  StreamSubscription<StepCount>? _stepSub;
  bool _sensorLangkahTersedia = false;
  int? _stepBaseline;
  int _sensorStepCount = 0;

  // Split Kilometer & Series Kecepatan
  final List<SplitKilometer> _splitList = [];
  final List<double> _speedSamples = [];
  int _lastSplitKm = 0;
  Duration _lastSplitDuration = Duration.zero;

  late final AnimationController _livePulseController;

  double get _userWeightKg =>
      AuthService.instance.currentUser?.beratBadan ?? 65.0;

  bool get _isBerlari => _jenisAktivitas == 'Berlari';

  bool get _isInFocusMode => _isPreparing || _isTracking;

  /// Menggunakan sensor langkah hardware jika tersedia & aktif,
  /// atau estimasi langkah akurat berdasarkan jarak tempuh.
  int get _effectiveSteps {
    if (_sensorLangkahTersedia && _sensorStepCount > 0) {
      return _sensorStepCount;
    }
    return TrackingCalculator.estimasiLangkahDariJarak(
      jarakMeter: _totalDistanceMeters,
      tinggiBadanCm: 170.0,
      isBerlari: _isBerlari,
    );
  }

  void _syncFocusNavigationState() {
    TrackingSessionController.isSessionActive.value =
        _isPreparing || _isTracking;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TrackingSessionController.onBackPressedDuringSession =
        _handleBackDuringSession;
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
    if (TrackingSessionController.onBackPressedDuringSession ==
        _handleBackDuringSession) {
      TrackingSessionController.onBackPressedDuringSession = null;
    }
    _prepTimer?.cancel();
    _uiTimer?.cancel();
    _positionSub?.cancel();
    _stepSub?.cancel();
    _livePulseController.dispose();
    if (!_isTracking && !_isPreparing) {
      TrackingSessionController.isSessionActive.value = false;
    }
    super.dispose();
  }

  void _handleBackDuringSession() {
    if (_isPreparing) {
      _batalkanPersiapan();
    } else if (_isTracking) {
      _konfirmasiSelesaikan();
    }
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
          _gpsStatusText = 'GPS Nonaktif • Ketuk Aktifkan';
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
              ? 'Izin Lokasi Diblokir'
              : 'Izin Lokasi Diperlukan';
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
        _gpsStatusText = 'GPS Siap • Akurasi ±${pos.accuracy.round()}m';
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
  // 2. SENSOR LANGKAH (HARDWARE PEDOMETER + FALLBACK ESTIMASI)
  // ═════════════════════════════════════════════════════════════════════

  void _startStepSensor() {
    _stepSub?.cancel();
    _stepBaseline = null;

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (!mounted) return;
          _stepBaseline ??= event.steps - _sensorStepCount;
          if (!_isPaused) {
            final computed = event.steps - (_stepBaseline ?? event.steps);
            setState(() {
              _sensorLangkahTersedia = true;
              _sensorStepCount = computed >= 0 ? computed : 0;
            });
          } else {
            _stepBaseline = event.steps - _sensorStepCount;
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
  // 3. FASE PERSIAPAN 30 DETIK & KONTROL SESI TRACKING
  // ═════════════════════════════════════════════════════════════════════

  Future<void> _mulaiPersiapan() async {
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
    if (!mounted) return;

    _prepTimer?.cancel();
    setState(() {
      _isPreparing = true;
      _prepSecondsRemaining = _durasiPersiapanDetik;
      _followUser = true;
      _syncFocusNavigationState();
    });

    _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPreparing) {
        timer.cancel();
        return;
      }

      if (_prepSecondsRemaining <= 1) {
        timer.cancel();
        _mulaiSesiAktif();
      } else {
        setState(() {
          _prepSecondsRemaining -= 1;
        });
        if (_prepSecondsRemaining <= 3) {
          HapticFeedback.selectionClick();
        }
      }
    });
  }

  void _batalkanPersiapan() {
    HapticFeedback.lightImpact();
    _prepTimer?.cancel();
    setState(() {
      _isPreparing = false;
      _prepSecondsRemaining = _durasiPersiapanDetik;
      _syncFocusNavigationState();
    });
  }

  Future<void> _mulaiSesiAktif() async {
    _prepTimer?.cancel();
    HapticFeedback.heavyImpact();

    final startCoord = _posisiSaatIni;
    final now = DateTime.now();

    setState(() {
      _isPreparing = false;
      _prepSecondsRemaining = _durasiPersiapanDetik;
      _isTracking = true;
      _syncFocusNavigationState();

      _isPaused = false;
      _activeSegmentStart = now;
      _accumulatedActiveDuration = Duration.zero;
      _elapsedSeconds = 0;

      _totalDistanceMeters = 0.0;
      _currentSpeedKmh = 0.0;
      _averageSpeedKmh = 0.0;
      _caloriesBurned = 0.0;

      _sensorStepCount = 0;
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

  void _pauseSesi() {
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

  void _lanjutkanSesi() {
    if (!_isTracking || !_isPaused) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isPaused = false;
      _activeSegmentStart = DateTime.now();
      _lastValidPosition = null;
    });

    _persistActiveBackup();
  }

  Future<void> _konfirmasiSelesaikan() async {
    HapticFeedback.mediumImpact();

    final wasPaused = _isPaused;
    if (!wasPaused) {
      _pauseSesi();
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
                'Selesaikan Sesi?',
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
          'Sesi $_jenisAktivitas akan diakhiri dan hasilnya disimpan ke riwayat aktivitasmu.',
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
              'Batal',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077E6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
            child: const Text(
              'Ya, Selesaikan',
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
        _lanjutkanSesi();
      }
      return;
    }

    await _selesaikanDanSimpan();
  }

  Future<void> _selesaikanDanSimpan() async {
    _prepTimer?.cancel();
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
    final langkahCopy = _effectiveSteps;
    final isStepEstimatedCopy = !_sensorLangkahTersedia || _sensorStepCount == 0;
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
      sensorLangkahTersedia: true,
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

    // Kembalikan state halaman Tracking ke mode siap (Bottom Nav Bar muncul lagi)
    setState(() {
      _isPreparing = false;
      _isTracking = false;
      _syncFocusNavigationState();
      _isPaused = false;
      _activeSegmentStart = null;
      _accumulatedActiveDuration = Duration.zero;
      _elapsedSeconds = 0;
      _totalDistanceMeters = 0.0;
      _currentSpeedKmh = 0.0;
      _averageSpeedKmh = 0.0;
      _caloriesBurned = 0.0;
      _sensorStepCount = 0;
      _rutePoints.clear();
    });

    // Jalankan kembali stream lokasi pasif agar marker posisi pengguna tetap aktif
    _initInitialGps();

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _, _) => RingkasanSesiScreen(
          jenisOlahraga: jenisCopy,
          tanggal: 'Hari ini',
          durasiMenit: durasiMenit.toString(),
          durasiFormatted: durasiFormatted,
          jarakKm: jarakKm.toStringAsFixed(2).replaceAll('.', ','),
          jarakMeter: _totalDistanceMeters,
          langkah: langkahCopy.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]}.',
              ),
          sensorLangkahTersedia: true,
          isStepEstimated: isStepEstimatedCopy,
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
        'stepCount': _sensorStepCount,
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
        _syncFocusNavigationState();
        _isPaused = true;
        _accumulatedActiveDuration = Duration(seconds: savedSeconds);
        _elapsedSeconds = savedSeconds;
        _totalDistanceMeters =
            (data['distanceMeters'] as num?)?.toDouble() ?? 0.0;
        _sensorStepCount = (data['stepCount'] as num?)?.toInt() ?? 0;
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
  // 5. BUILD UI FULL-SCREEN STRAVA-INSPIRED TRACKING
  // ═════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomControlsPadding = _isTracking
        ? (screenHeight < 700 ? 255.0 : 275.0)
        : (_isPreparing
            ? (screenHeight < 700 ? 245.0 : 265.0)
            : (screenHeight < 700 ? 225.0 : 240.0));

    final gpsColor = !_gpsServiceEnabled ||
            _locationPermission == LocationPermission.denied ||
            _locationPermission == LocationPermission.deniedForever
        ? const Color(0xFFDC2626)
        : (_isGpsLoading
            ? const Color(0xFFF59E0B)
            : const Color(0xFF059669));

    return PopScope(
      canPop: !_isInFocusMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isInFocusMode) {
          _handleBackDuringSession();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        // Hilangkan seluruh area BottomNavigationBar secara otomatis saat persiapan & sesi aktif
        bottomNavigationBar: (!_isInFocusMode && widget.showBottomNav)
            ? const AppBottomNavBar(currentIndex: 2)
            : null,
        body: Stack(
          children: [
            // ── 1. FULL-SCREEN OPENSTREETMAP ────────────────────────
            Positioned.fill(
              child: OsmTrackingMap(
                rutePoints: _rutePoints,
                posisiSaatIni: _posisiSaatIni,
                posisiAwal: _posisiAwal,
                followUser: _followUser,
                isTrackingActive: _isTracking && !_isPaused,
                isGpsLoading: _isGpsLoading,
                showTopStatusBadge: false,
                showZoomControls: true,
                controlsBottomPadding: bottomControlsPadding,
                gpsStatusText: _gpsStatusText,
                gpsStatusColor: gpsColor,
                onToggleFollow: () {
                  setState(() => _followUser = true);
                },
              ),
            ),

            // ── 2. TOP OVERLAY: KIRI (BACK / STATUS) & KANAN (LOGO GERAK) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isPreparing)
                        _buildPreparationStatusPill()
                      else if (_isTracking)
                        _buildActiveStatusPill()
                      else
                        _FrostedOverlayPill(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Color(0xFF0077E6),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Beranda',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sisi Kanan: Logo & Identitas GERAK Minimalis
                      const _GerakTopRightLogoBadge(),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. BOTTOM FLOATING PANEL (PRA-SESI / PERSIAPAN / TRACKING AKTIF) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                bottom: _isInFocusMode || !widget.showBottomNav,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _isPreparing
                      ? _buildPreparationPanel()
                      : (_isTracking
                          ? _buildActiveTrackingPanel()
                          : _buildPreSessionPanel(gpsColor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pill Status Persiapan di Kiri Atas ──────────────────────────────
  Widget _buildPreparationStatusPill() {
    return _FrostedOverlayPill(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      borderColor: const Color(0xFFBAE6FD),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFF0077E6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'PERSIAPAN • $_prepSecondsRemaining DETIK',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Color(0xFF0077E6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pill Status Tracking di Kiri Atas (Saat Sesi Aktif) ──────────────
  Widget _buildActiveStatusPill() {
    final isPaused = _isPaused;
    final dotColor =
        isPaused ? const Color(0xFFD97706) : const Color(0xFF0077E6);

    return _FrostedOverlayPill(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      borderColor: isPaused
          ? const Color(0xFFFDE68A)
          : const Color(0xFFBAE6FD),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _livePulseController,
            builder: (_, _) => Opacity(
              opacity:
                  isPaused ? 1.0 : (0.4 + _livePulseController.value * 0.6),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPaused ? 'DIJEDA' : 'TRACKING AKTIF',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── PANEL BAWAH: JEDA PERSIAPAN 30 DETIK (SEDERHANA & BERSIH) ────────
  Widget _buildPreparationPanel() {
    final progress = _prepSecondsRemaining / _durasiPersiapanDetik;

    return Container(
      key: const ValueKey('preparation_panel'),
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bersiap Memulai $_jenisAktivitas',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lakukan peregangan singkat sebelum sesi dimulai otomatis',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Lingkaran Hitung Mundur 30 Detik Sederhana
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFE0F2FE),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0077E6),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_prepSecondsRemaining',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0077E6),
                        fontFeatures: [FontFeature.tabularFigures()],
                        height: 1.05,
                      ),
                    ),
                    const Text(
                      'detik',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tombol Batalkan & Mulai Sekarang
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _batalkanPersiapan,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batalkan',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _mulaiSesiAktif,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077E6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Mulai Sekarang',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PANEL BAWAH 1: SEBELUM MEMULAI SESI (MODERN & MINIMALIS) ─────────
  Widget _buildPreSessionPanel(Color gpsColor) {
    final hasGpsIssue = !_gpsServiceEnabled ||
        _locationPermission == LocationPermission.denied ||
        _locationPermission == LocationPermission.deniedForever;

    final estimasiKalori30Mnt = TrackingCalculator.hitungKaloriMet(
      met: _isBerlari ? 8.3 : 3.6,
      beratBadanKg: _userWeightKg,
      durasiMenit: 30,
    ).round();

    return Container(
      key: const ValueKey('pre_session_panel'),
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1: Status GPS + Pintasan Riwayat
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gpsColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isGpsLoading)
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: gpsColor,
                        ),
                      )
                    else
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: gpsColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _gpsStatusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: gpsColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (hasGpsIssue)
                GestureDetector(
                  onTap: () async {
                    if (!_gpsServiceEnabled) {
                      await Geolocator.openLocationSettings();
                    } else {
                      await _initInitialGps();
                    }
                  },
                  child: const Text(
                    'Aktifkan GPS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0077E6),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RiwayatOlahragaScreen(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 15, color: Color(0xFF0077E6)),
                      SizedBox(width: 4),
                      Text(
                        'Riwayat',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0077E6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Baris 2: Pilihan Jenis Aktivitas Ringkas
          Row(
            children: [
              Expanded(
                child: _CompactSportSelector(
                  label: 'Berlari',
                  icon: Icons.directions_run_rounded,
                  selected: _jenisAktivitas == 'Berlari',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _jenisAktivitas = 'Berlari');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactSportSelector(
                  label: 'Berjalan Kaki',
                  icon: Icons.directions_walk_rounded,
                  selected: _jenisAktivitas == 'Berjalan',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _jenisAktivitas = 'Berjalan');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Baris 3: Ringkasan Singkat Aktivitas yang Akan Dilakukan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route_rounded,
                        size: 15, color: Color(0xFF0077E6)),
                    const SizedBox(width: 6),
                    Text(
                      'Jeda siap 30d • $_jenisAktivitas',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                Text(
                  '~$estimasiKalori30Mnt kcal/30m',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0077E6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Baris 4: Tombol Utama Mulai Sesi
          _PrimarySportButton(
            label: 'Mulai Sesi',
            icon: Icons.play_arrow_rounded,
            onPressed: _mulaiPersiapan,
          ),
        ],
      ),
    );
  }

  // ── PANEL BAWAH 2: KETIKA TRACKING BERLANGSUNG (STRAVA-INSPIRED) ─────
  Widget _buildActiveTrackingPanel() {
    final jarakKm = _totalDistanceMeters / 1000.0;
    final avgPaceMin =
        jarakKm > 0.01 ? (_elapsedSeconds / 60.0) / jarakKm : 0.0;
    final paceShort = TrackingCalculator.formatPaceShort(avgPaceMin);

    return ClipRRect(
      key: const ValueKey('active_tracking_panel'),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.93),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: const Border(
              top: BorderSide(color: Color(0xFFDBEAFE), width: 1.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indikator & status aktivitas
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isBerlari
                            ? Icons.directions_run_rounded
                            : Icons.directions_walk_rounded,
                        color: const Color(0xFF0077E6),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sesi $_jenisAktivitas',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _isPaused
                        ? 'Aktivitas dijeda sementara'
                        : 'Merekam rute real-time',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _isPaused
                          ? const Color(0xFFD97706)
                          : const Color(0xFF0077E6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2 Metrik Utama Besar (Durasi & Jarak km) ala Strava
              Row(
                children: [
                  Expanded(
                    child: _HeroTelemetryBlock(
                      label: 'DURASI',
                      value:
                          TrackingCalculator.formatDurasiHms(_elapsedSeconds),
                      unit: '',
                    ),
                  ),
                  Container(
                    width: 1.2,
                    height: 44,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _HeroTelemetryBlock(
                      label: 'JARAK',
                      value: jarakKm.toStringAsFixed(2).replaceAll('.', ','),
                      unit: 'km',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3 Metrik Pendukung (Estimasi Langkah, Estimasi Kalori, Pace)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SubTelemetryItem(
                        icon: Icons.directions_walk_rounded,
                        iconColor: const Color(0xFF0077E6),
                        label: 'Est. Langkah',
                        value: '$_effectiveSteps',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFDBEAFE),
                    ),
                    Expanded(
                      child: _SubTelemetryItem(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Est. Kalori',
                        value: '${_caloriesBurned.round()} kcal',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFDBEAFE),
                    ),
                    Expanded(
                      child: _SubTelemetryItem(
                        icon: Icons.speed_rounded,
                        iconColor: const Color(0xFF0284C7),
                        label: 'Pace',
                        value: '$paceShort/km',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Tombol Kontrol: Pause / Lanjutkan & Selesaikan
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPaused ? _lanjutkanSesi : _pauseSesi,
                        icon: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        label: Text(
                          _isPaused ? 'Lanjutkan' : 'Pause',
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
                          elevation: 0,
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
                        onPressed: _konfirmasiSelesaikan,
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Selesaikan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2B5C),
                          elevation: 0,
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
}

// ═══════════════════════════════════════════════════════════════════════
// LOGO & IDENTITAS GERAK DI POJOK KANAN ATAS
// ═══════════════════════════════════════════════════════════════════════

class _GerakTopRightLogoBadge extends StatelessWidget {
  const _GerakTopRightLogoBadge();

  @override
  Widget build(BuildContext context) {
    return _FrostedOverlayPill(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/logo_gerak.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/gerak_logo.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/logo.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0077E6), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'GERAK',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0077E6),
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostedOverlayPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final VoidCallback? onTap;

  const _FrostedOverlayPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderColor = const Color(0xFFE2E8F0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUB-WIDGET KOMPONEN TRACKING
// ═══════════════════════════════════════════════════════════════════════

class _CompactSportSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CompactSportSelector({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0077E6) : const Color(0xFFF1F7FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                selected ? const Color(0xFF0077E6) : const Color(0xFFDBEAFE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : const Color(0xFF0077E6),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTelemetryBlock extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _HeroTelemetryBlock({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0077E6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SubTelemetryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SubTelemetryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimarySportButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimarySportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_PrimarySportButton> createState() => _PrimarySportButtonState();
}

class _PrimarySportButtonState extends State<_PrimarySportButton> {
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
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}