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

  // Konfigurasi tampilan Full-Screen & Preview Ringkasan
  final bool isReadOnly;
  final bool isTrackingActive;
  final bool isGpsLoading;
  final bool showTopStatusBadge;
  final bool showZoomControls;
  final double controlsBottomPadding;
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
    this.showTopStatusBadge = true,
    this.showZoomControls = true,
    this.controlsBottomPadding = 16.0,
    this.gpsStatusText,
    this.gpsStatusColor = const Color(0xFF059669),
    this.onGpsActionTap,
    this.gpsActionLabel,
    this.borderRadius = 0.0,
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

    final mapStack = Stack(
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
                  Polyline(
                    points: widget.rutePoints,
                    strokeWidth: 10.0,
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.36),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                  Polyline(
                    points: widget.rutePoints,
                    strokeWidth: 5.5,
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
                    width: 54,
                    height: 54,
                    child: widget.isReadOnly
                        ? _buildFinishMarker()
                        : _buildCurrentLocationMarker(),
                  ),
              ],
            ),
          ],
        ),

        // ── 2. Badge Status GPS (Opsional untuk Mode Preview) ────
        if (widget.showTopStatusBadge && widget.gpsStatusText != null)
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
          ),

        // ── 3. Tombol My Location & Zoom (Kanan Bawah di Atas Panel) ──
        if (!widget.isReadOnly || widget.showZoomControls)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: widget.controlsBottomPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showZoomControls) ...[
                  _MapControlButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Perbesar Peta',
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 6),
                  _MapControlButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Perkecil Peta',
                    onTap: _zoomOut,
                  ),
                  if (!widget.isReadOnly) const SizedBox(height: 10),
                ],
                if (!widget.isReadOnly)
                  GestureDetector(
                    onTap: _centerToLocation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.followUser
                            ? const Color(0xFF0077E6)
                            : Colors.white.withValues(alpha: 0.96),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.followUser
                              ? Colors.white
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: widget.followUser
                            ? Colors.white
                            : const Color(0xFF0077E6),
                        size: 21,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // ── 4. Attribution OpenStreetMap Minimalis ───────────────
        Positioned(
          left: 12,
          bottom: widget.isReadOnly ? 8 : (widget.controlsBottomPadding - 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '© OpenStreetMap',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: mapStack,
      );
    }
    return mapStack;
  }

  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, _) {
        final scale = 0.86 + (_pulseController.value * 0.28);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF0077E6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0077E6).withValues(alpha: 0.48),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 13,
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

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF1E293B)),
        ),
      ),
    );
  }
}