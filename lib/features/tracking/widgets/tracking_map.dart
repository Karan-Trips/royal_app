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
  });

  final MapController mapController;
  final TrackingState tracking;
  final MapStyle mapStyle;
  final Animation<double> pulseAnim;
  final LatLng initialCenter;
  final double zoom;
  final VoidCallback onGesture;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: zoom,
        onPositionChanged: (_, gesture) {
          if (gesture) onGesture();
        },
      ),
      children: [
        // ── Tile layer ──────────────────────────────────────────────────
        TileLayer(
          urlTemplate: mapStyle.urlTemplate,
          subdomains: mapStyle.subdomains,
          userAgentPackageName: 'com.motostack.royal_app',
        ),

        // ── Trail shadow ────────────────────────────────────────────────
        if (tracking.points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: tracking.points,
                color: Colors.black.withValues(alpha: 0.5),
                strokeWidth: 9,
              ),
            ],
          ),

        // ── Orange RE trail ─────────────────────────────────────────────
        if (tracking.points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: tracking.points,
                color: const Color(0xFFFF6B00),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),

        // ── Start marker ────────────────────────────────────────────────
        if (tracking.points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: tracking.points.first,
                width: 28,
                height: 28,
                child: _StartMarker(),
              ),
            ],
          ),

        // ── Current position + bearing arrow ────────────────────────────
        if (tracking.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: tracking.currentPosition!,
                width: 60,
                height: 60,
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
}

// ── Start marker ───────────────────────────────────────────────────────────────

class _StartMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.flag_rounded, color: Colors.black, size: 14),
    );
  }
}

// ── Animated position + bearing marker ────────────────────────────────────────

class _PositionMarker extends StatelessWidget {
  const _PositionMarker({required this.tracking, required this.pulseAnim});

  final TrackingState tracking;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 60 * pulseAnim.value,
            height: 60 * pulseAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(
                0xFFFF6B00,
              ).withValues(alpha: 0.12 * pulseAnim.value),
            ),
          ),

          // Inner accuracy ring
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          ),

          // Bearing cone (only while tracking)
          if (tracking.isTracking)
            Transform.rotate(
              angle: tracking.heading * math.pi / 180,
              child: CustomPaint(
                size: const Size(60, 60),
                painter: _BearingConePainter(),
              ),
            ),

          // Core dot / navigation arrow
          if (tracking.isTracking)
            Transform.rotate(
              angle: tracking.heading * math.pi / 180,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            )
          else
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B00),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.6),
                    blurRadius: 8,
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

// ── Bearing cone painter ───────────────────────────────────────────────────────

class _BearingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6B00).withValues(alpha: 0.35),
          const Color(0xFFFF6B00).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: cx));

    final path = ui.Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - cx * 0.45, 0)
      ..lineTo(cx + cx * 0.45, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BearingConePainter old) => false;
}
