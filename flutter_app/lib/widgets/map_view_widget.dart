// lib/widgets/map_view_widget.dart
/// Reusable map widget for location display across Taxi/Food/Massage/Hotel
///
/// Modes:
///   - [MapViewMode.marker] — single marker at [markers]
///   - [MapViewMode.route] — two markers with polyline
///   - [MapViewMode.radius] — center marker + radius circle
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/design_system/app_colors.dart';

/// Modes for the map widget.
enum MapViewMode {
  marker,   // single location pin
  route,    // A→B with line
  radius,   // center + search radius circle
}

/// A single point on the map.
class MapPoint {
  final double lat;
  final double lng;
  final String label;

  const MapPoint({
    required this.lat,
    required this.lng,
    this.label = '',
  });
}

/// An interactive map widget built with OpenStreetMap (flutter_map).
///
/// No Google Maps API key needed for tiles. Google Places/Geocode APIs
/// (configured sever‑side) provide the address data; this widget renders it.
class MapViewWidget extends StatefulWidget {
  final MapViewMode mode;
  final List<MapPoint> markers;
  final double? radiusKm;
  final LatLng? center;
  final double initialZoom;
  final double height;
  final bool interactive;
  final void Function(LatLng point)? onTap;

  /// Called when the user long‑presses / taps to add a marker.
  final void Function(LatLng point)? onMapTapped;

  const MapViewWidget({
    super.key,
    this.mode = MapViewMode.marker,
    this.markers = const [],
    this.radiusKm,
    this.center,
    this.initialZoom = 14,
    this.height = 260,
    this.interactive = true,
    this.onTap,
    this.onMapTapped,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Compute bounds so all markers are visible ──
  LatLngBounds? _computeBounds() {
    if (widget.markers.isEmpty) return null;
    if (widget.markers.length == 1) {
      final m = widget.markers.first;
      return LatLngBounds(
        LatLng(m.lat - 0.01, m.lng - 0.01),
        LatLng(m.lat + 0.01, m.lng + 0.01),
      );
    }
    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;
    for (final m in widget.markers) {
      if (m.lat < minLat) minLat = m.lat;
      if (m.lat > maxLat) maxLat = m.lat;
      if (m.lng < minLng) minLng = m.lng;
      if (m.lng > maxLng) maxLng = m.lng;
    }
    // Add padding
    final latPad = (maxLat - minLat) * 0.3 + 0.005;
    final lngPad = (maxLng - minLng) * 0.3 + 0.005;
    return LatLngBounds(
      LatLng(minLat - latPad, minLng - lngPad),
      LatLng(maxLat + latPad, maxLng + lngPad),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _computeBounds();
    final center = widget.center ??
        (widget.markers.isNotEmpty
            ? LatLng(widget.markers.first.lat, widget.markers.first.lng)
            : const LatLng(37.5665, 126.9780)); // Seoul default

    final showLabelBg = AppColors.background; // #020617

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: widget.initialZoom,
          interactionOptions: InteractionOptions(
            flags: widget.interactive
                ? InteractiveFlag.all & ~InteractiveFlag.rotate
                : InteractiveFlag.none,
          ),
          onTap: widget.onMapTapped != null
              ? (tapPos, latlng) => widget.onMapTapped!(latlng)
              : null,
          // Auto-fit bounds after map is built
          onMapReady: () {
            if (bounds != null && widget.markers.length > 1) {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60),
                ),
              );
            }
          },
        ),
        children: [
          // ── Tile Layer (OpenStreetMap, dark style) ──
          TileLayer(
            urlTemplate:
                'https://tile.jawg.io/jawg-dark/{z}/{x}/{y}{r}.png?access-token=BM0Bph5V4bMwGQJYlELndLwWQJqCTqgYH7Odx6qfrLVUPJKLIYg9bLtFPySWoYQb',
            userAgentPackageName: 'com.liberty.reach',
          ),

          // ── Radius Circle ──
          if (widget.mode == MapViewMode.radius && widget.radiusKm != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderColor: AppColors.primary.withValues(alpha: 0.4),
                  borderStrokeWidth: 2,
                  radius: widget.radiusKm! * 1000, // km → m
                ),
              ],
            ),

          // ── Route Polyline ──
          if (widget.mode == MapViewMode.route && widget.markers.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.markers
                      .map((m) => LatLng(m.lat, m.lng))
                      .toList(),
                  color: AppColors.primary.withValues(alpha: 0.6),
                  strokeWidth: 3,
                ),
              ],
            ),

          // ── Markers ──
          MarkerLayer(
            markers: List.generate(widget.markers.length, (i) {
              final m = widget.markers[i];
              bool isOrigin = widget.mode == MapViewMode.route && i == 0;
              bool isDest = widget.mode == MapViewMode.route && i > 0;
              return Marker(
                point: LatLng(m.lat, m.lng),
                width: 100,
                height: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label above pin
                    if (m.label.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: showLabelBg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          m.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    // Pin icon
                    Icon(
                      isOrigin
                          ? Icons.trip_origin
                          : isDest
                              ? Icons.flag
                              : Icons.location_on,
                      color: isOrigin
                          ? const Color(0xFF22C55E)
                          : AppColors.primary,
                      size: isOrigin || isDest ? 32 : 36,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
