import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:royal_app/features/tracking/providers/tracking_provider.dart';
import 'package:royal_app/features/tracking/widgets/map_style.dart';

class TrackingMap extends StatelessWidget {
  const TrackingMap({
    super.key,
    required this.mapController,
    required this.tracking,
    required this.mapStyle,
    required this.pulseAnim,
    required this.initialCenter,
    required this.zoom,
    required this.onGesture,
    this.showRadiusCircle = false,
  });

  final MapController mapController;
  final TrackingState tracking;
  final MapStyle mapStyle;
  final Animation<double> pulseAnim;
  final LatLng initialCenter;
  final double zoom;
  final VoidCallback onGesture;
  final bool showRadiusCircle; // toggleable radius feature

  @override
  Widget build(BuildContext context) {
    final pos = tracking.currentPosition;
    final points = tracking.points;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: zoom,
        // Disable map rotation by user gesture — we control it via bearing
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: (_, gesture) {
          if (gesture) onGesture();
        },
      ),
      children: [
        // ── 1. Tile layer ───────────────────────────────────────────────
        TileLayer(
          urlTemplate: mapStyle.urlTemplate,
          subdomains: mapStyle.subdomains,
          userAgentPackageName: 'com.motostack.royal_app',
          tileBuilder: mapStyle == MapStyle.dark ? _darkTileBuilder : null,
        ),

        // ── 2. Distance radius circle (500 m from start) ────────────────
        if (showRadiusCircle && points.isNotEmpty)
          CircleLayer(
            circles: [
              CircleMarker(
                point: points.first,
                radius: 500, // metres
                useRadiusInMeter: true,
                color: const Color(0xFFFF6B00).withValues(alpha: 0.06),
                borderColor: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              
              ),
            ],
          ),

        // ── 3. Accuracy circle around current position ──────────────────
        if (pos != null && tracking.accuracy > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: pos,
                radius: tracking.accuracy,
                useRadiusInMeter: true,
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.08),
                borderColor: const Color(0xFF4FC3F7).withValues(alpha: 0.25),
              ),
            ],
          ),

        // ── 4. Trail shadow (thick dark underline) ──────────────────────
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: Colors.black.withValues(alpha: 0.45),
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // ── 5. Main orange trail ────────────────────────────────────────
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: const Color(0xFFFF6B00),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // ── 6. Bright leading edge (last 5 points glow) ─────────────────
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points.length > 5
                    ? points.sublist(points.length - 5)
                    : points,
                color: const Color(0xFFFFCC00),
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),

        // ── 7. Start marker ─────────────────────────────────────────────
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: points.first,
                width: 32,
                height: 32,
                child: const _StartMarker(),
              ),
            ],
          ),

        // ── 8. End / last-stop marker (when stopped) ────────────────────
        if (!tracking.isTracking && points.length >= 2)
          MarkerLayer(
            markers: [
              Marker(
                point: points.last,
                width: 32,
                height: 32,
                child: const _EndMarker(),
              ),
            ],
          ),

        // ── 9. Current position marker with bearing cone ────────────────
        if (pos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: pos,
                width: 80,
                height: 80,
                child: _PositionMarker(
                  tracking: tracking,
                  pulseAnim: pulseAnim,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Darkens standard OSM tiles slightly for better contrast
  Widget _darkTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.8,
        0,
        0,
        0,
        0,
        0,
        0.8,
        0,
        0,
        0,
        0,
        0,
        0.8,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tileWidget,
    );
  }
}

// ── Start Marker ───────────────────────────────────────────────────────────────

class _StartMarker extends StatelessWidget {
  const _StartMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00C853),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 14),
    );
  }
}

// ── End Marker ─────────────────────────────────────────────────────────────────

class _EndMarker extends StatelessWidget {
  const _EndMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.redAccent,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.sports_score_rounded,
        color: Colors.white,
        size: 14,
      ),
    );
  }
}

// ── Position Marker ────────────────────────────────────────────────────────────

class _PositionMarker extends StatelessWidget {
  const _PositionMarker({required this.tracking, required this.pulseAnim});

  final TrackingState tracking;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    // Convert heading degrees → radians for Transform.rotate
    final headingRad = tracking.heading * math.pi / 180;

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer expanding pulse ring ──────────────────────────────
          Opacity(
            opacity: (1 - pulseAnim.value) * 0.6,
            child: Container(
              width: 80 * pulseAnim.value,
              height: 80 * pulseAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
              ),
            ),
          ),

          // ── Bearing cone (direction of travel) ─────────────────────
          if (tracking.isTracking)
            Transform.rotate(
              angle: headingRad,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _BearingConePainter(color: const Color(0xFFFF6B00)),
              ),
            ),

          // ── Accuracy ring ───────────────────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),

          // ── Core navigation arrow (rotates with heading) ────────────
          if (tracking.isTracking)
            Transform.rotate(
              angle: headingRad,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFAA00), Color(0xFFFF4500)],
                    center: Alignment(-0.3, -0.3),
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.8),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            )
          // ── Static dot when not tracking ────────────────────────────
          else
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4FC3F7),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bearing Cone Painter ───────────────────────────────────────────────────────
// Draws a soft gradient cone pointing upward (north = 0°).
// The marker is then rotated by the heading angle.

class _BearingConePainter extends CustomPainter {
  const _BearingConePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        cx,
        [color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
        [0.0, 1.0],
      );

    // Cone spans ±30° from heading (60° total field of view)
    const halfAngle = 30 * math.pi / 180;
    final path = ui.Path()
      ..moveTo(cx, cy)
      ..lineTo(
        cx + math.sin(-halfAngle) * cx * 1.4,
        cy - math.cos(-halfAngle) * cy * 1.4,
      )
      ..lineTo(
        cx + math.sin(halfAngle) * cx * 1.4,
        cy - math.cos(halfAngle) * cy * 1.4,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BearingConePainter old) => old.color != color;
}
