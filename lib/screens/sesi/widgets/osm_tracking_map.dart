import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmTrackingMap extends StatefulWidget {
  final List<LatLng> rutePoints;
  final LatLng? posisiSaatIni;
  final LatLng? posisiAwal;
  final double heading;
  final bool followUser;
  final VoidCallback onToggleFollow;
  final VoidCallback? onExpand;

  // Tambahan parameter opsional untuk tampilan modern & mode ringkasan rute
  final bool isReadOnly;
  final bool isTrackingActive;
  final bool isGpsLoading;
  final String? gpsStatusText;
  final Color gpsStatusColor;
  final VoidCallback? onGpsActionTap;
  final String? gpsActionLabel;
  final double borderRadius;

  const OsmTrackingMap({
    super.key,
    required this.rutePoints,
    required this.posisiSaatIni,
    required this.posisiAwal,
    this.heading = 0.0,
    this.followUser = true,
    required this.onToggleFollow,
    this.onExpand,
    this.isReadOnly = false,
    this.isTrackingActive = false,
    this.isGpsLoading = false,
    this.gpsStatusText,
    this.gpsStatusColor = const Color(0xFF059669),
    this.onGpsActionTap,
    this.gpsActionLabel,
    this.borderRadius = 22.0,
  });

  @override
  State<OsmTrackingMap> createState() => _OsmTrackingMapState();
}

class _OsmTrackingMapState extends State<OsmTrackingMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  // Default fallback titik awal (Jember, Indonesia)
  static const LatLng _defaultCenter = LatLng(-8.1724, 113.7007);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OsmTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isReadOnly &&
        widget.followUser &&
        widget.posisiSaatIni != null &&
        oldWidget.posisiSaatIni != widget.posisiSaatIni) {
      _mapController.move(widget.posisiSaatIni!, _mapController.camera.zoom);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(4.0, 19.0),
    );
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(4.0, 19.0),
    );
  }

  void _centerToLocation() {
    if (widget.posisiSaatIni != null) {
      _mapController.move(widget.posisiSaatIni!, 17.0);
    }
    widget.onToggleFollow();
  }

  /// Hitung titik tengah dan zoom otomatis untuk rute statis (Ringkasan / Detail)
  ({LatLng center, double zoom}) _computeInitialView() {
    if (widget.rutePoints.length > 1) {
      double minLat = widget.rutePoints.first.latitude;
      double maxLat = widget.rutePoints.first.latitude;
      double minLon = widget.rutePoints.first.longitude;
      double maxLon = widget.rutePoints.first.longitude;

      for (final p in widget.rutePoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
      }

      final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
      final span = math.max((maxLat - minLat).abs(), (maxLon - minLon).abs());

      double zoom = 16.5;
      if (span > 0.08) {
        zoom = 12.5;
      } else if (span > 0.04) {
        zoom = 13.5;
      } else if (span > 0.02) {
        zoom = 14.5;
      } else if (span > 0.008) {
        zoom = 15.5;
      } else if (span > 0.003) {
        zoom = 16.2;
      }
      return (center: center, zoom: zoom);
    }

    final center =
        widget.posisiSaatIni ?? widget.posisiAwal ?? _defaultCenter;
    return (center: center, zoom: 16.5);
  }

  @override
  Widget build(BuildContext context) {
    final view = _computeInitialView();

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          // ── 1. FlutterMap OpenStreetMap ──────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: view.center,
              initialZoom: view.zoom,
              minZoom: 4.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gerak.mobileapp',
                maxZoom: 19,
              ),

              // ── Garis Rute Biru GERAK ────────────────────────────
              if (widget.rutePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    // Outer soft blue glow
                    Polyline(
                      points: widget.rutePoints,
                      strokeWidth: 9.0,
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.38),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Core vibrant sport blue line
                    Polyline(
                      points: widget.rutePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF0077E6),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // ── Marker Titik Awal & Posisi Pengguna ──────────────
              MarkerLayer(
                markers: [
                  if (widget.posisiAwal != null)
                    Marker(
                      point: widget.posisiAwal!,
                      width: 34,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (widget.posisiSaatIni != null)
                    Marker(
                      point: widget.posisiSaatIni!,
                      width: 50,
                      height: 50,
                      child: widget.isReadOnly
                          ? _buildFinishMarker()
                          : _buildCurrentLocationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── 2. Badge Status GPS & Akurasi (Kiri Atas) ────────────
          if (widget.gpsStatusText != null)
            Positioned(
              top: 12,
              left: 12,
              right: 58,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.gpsStatusColor.withValues(alpha: 0.35),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isGpsLoading)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.gpsStatusColor,
                          ),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.gpsStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          widget.gpsStatusText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (widget.onExpand != null)
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: widget.onExpand,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.open_in_full_rounded,
                    color: Color(0xFF1E293B),
                    size: 18,
                  ),
                ),
              ),
            ),

          // ── 3. Tombol Re-Center & Zoom (Kanan Atas) ──────────────
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isReadOnly) ...[
                  GestureDetector(
                    onTap: _centerToLocation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: widget.followUser
                            ? const Color(0xFF0077E6)
                            : Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: widget.followUser
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 19, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.remove_rounded,
                        size: 19, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),

          // ── 4. Banner Aksi Jika GPS Mati / Izin Ditolak ───────────
          if (widget.onGpsActionTap != null && widget.gpsActionLabel != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 26,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Aktifkan layanan lokasi agar rute terekam akurat.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onGpsActionTap,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0077E6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.gpsActionLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 5. Attribution OpenStreetMap ─────────────────────────
          Positioned(
            left: 10,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, _) {
        final scale = 0.88 + (_pulseController.value * 0.24);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0077E6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0077E6).withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinishMarker() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF0077E6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077E6).withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_score_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}