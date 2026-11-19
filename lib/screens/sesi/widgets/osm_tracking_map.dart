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

  const OsmTrackingMap({
    super.key,
    required this.rutePoints,
    required this.posisiSaatIni,
    required this.posisiAwal,
    this.heading = 0.0,
    this.followUser = true,
    required this.onToggleFollow,
    this.onExpand,
  });

  @override
  State<OsmTrackingMap> createState() => _OsmTrackingMapState();
}

class _OsmTrackingMapState extends State<OsmTrackingMap> {
  late final MapController _mapController;

  // Default titik awal (Jember, Indonesia)
  static const LatLng _defaultCenter = LatLng(-8.1724, 113.7007);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant OsmTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followUser && widget.posisiSaatIni != null) {
      if (oldWidget.posisiSaatIni != widget.posisiSaatIni) {
        _mapController.move(widget.posisiSaatIni!, _mapController.camera.zoom);
      }
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _centerToLocation() {
    if (widget.posisiSaatIni != null) {
      _mapController.move(widget.posisiSaatIni!, 17.0);
    }
    widget.onToggleFollow();
  }

  @override
  Widget build(BuildContext context) {
    final centerPoint = widget.posisiSaatIni ?? widget.posisiAwal ?? _defaultCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // ── FlutterMap dengan OpenStreetMap Tile Server ──────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 16.5,
              minZoom: 4.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // 1. TileLayer OSM
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gerak.mobileapp',
                maxZoom: 19,
              ),

              // 2. Polyline Rute Jejak Perjalanan
              if (widget.rutePoints.length > 1) ...[
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.rutePoints,
                      strokeWidth: 8.0,
                      color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    Polyline(
                      points: widget.rutePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFFDC2626),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              ],

              // 3. Markers: Titik Awal & Posisi Real-time Saat Ini
              MarkerLayer(
                markers: [
                  if (widget.posisiAwal != null)
                    Marker(
                      point: widget.posisiAwal!,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  if (widget.posisiSaatIni != null)
                    Marker(
                      point: widget.posisiSaatIni!,
                      width: 48,
                      height: 48,
                      child: _buildCurrentLocationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // ── Tombol Kontrol Peta (Kiri Atas & Kanan Atas) ─────────────────
          Positioned(
            top: 14,
            left: 14,
            child: GestureDetector(
              onTap: widget.onExpand,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.open_in_full_rounded,
                  color: Color(0xFF1E293B),
                  size: 19,
                ),
              ),
            ),
          ),

          Positioned(
            top: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _centerToLocation,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.followUser
                          ? const Color(0xFF0077E6)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: widget.followUser ? Colors.white : const Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _zoomIn,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _zoomOut,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.remove_rounded, size: 20, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),

          // ── Attribution OpenStreetMap (Responsif) ────────────────────
          Positioned(
            left: 12,
            right: 12,
            bottom: 4,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
            shape: BoxShape.circle,
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
                color: const Color(0xFF0077E6).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
  }
}