import 'package:go_router/go_router.dart';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/history/domain/ride_entity.dart';

class HistoryMapScreen extends StatefulWidget {
  const HistoryMapScreen({super.key, required this.ride});
  final RideEntity ride;

  @override
  State<HistoryMapScreen> createState() => _HistoryMapScreenState();
}

class _HistoryMapScreenState extends State<HistoryMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _progress;
  late final List<LatLng>        _allPoints;
  late final MapController       _mapCtrl;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _allPoints = widget.ride.decodedPoints;
    _mapCtrl   = MapController();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    // Small delay so map tiles load before animation starts
    Future.delayed(const Duration(milliseconds: 400), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  LatLng get _center {
    if (_allPoints.isEmpty) return const LatLng(23.0225, 72.5714);
    final lat = _allPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
        _allPoints.length;
    final lng = _allPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
        _allPoints.length;
    return LatLng(lat, lng);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ride    = widget.ride;
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFFFF6B00), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFmt.format(ride.timestamp),
              style: AppFonts.heading(
                  size: 14, color: Colors.white, letterSpacing: 1),
            ),
            Text(
              timeFmt.format(ride.timestamp),
              style: AppFonts.caption(color: Colors.white38, size: 10),
            ),
          ],
        ),
        actions: [
          // Toggle detail panel
          IconButton(
            icon: FaIcon(
              _showDetails ? AppIcons.close : AppIcons.info,
              color: const Color(0xFFFF6B00),
              size: 16,
            ),
            onPressed: () => setState(() => _showDetails = !_showDetails),
          ),
          // Replay animation
          IconButton(
            icon: const FaIcon(AppIcons.play, color: Color(0xFFFF6B00), size: 14),
            onPressed: () {
              _ctrl.reset();
              _ctrl.forward();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _progress,
            builder: (_, child) {
              final count = (_allPoints.length * _progress.value)
                  .ceil()
                  .clamp(0, _allPoints.length);
              final visible = _allPoints.sublist(0, count);

              return FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                ),
                children: [
                  // OSM dark-ish tile layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.royalapp.app',
                  ),

                  // Animated polyline
                  if (visible.length >= 2)
                    PolylineLayer(
                      polylines: [
                        // Shadow
                        Polyline(
                          points: visible,
                          color: Colors.black.withValues(alpha: 0.4),
                          strokeWidth: 7,
                        ),
                        // Main orange trail
                        Polyline(
                          points: visible,
                          color: const Color(0xFFFF6B00),
                          strokeWidth: 4,
                        ),
                      ],
                    ),

                  // Start marker (green)
                  if (_allPoints.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _allPoints.first,
                          width: 28,
                          height: 28,
                          child: _MapPin(
                            color: const Color(0xFF69F0AE),
                            icon: AppIcons.flag,
                          ),
                        ),
                      ],
                    ),

                  // End marker (orange) — only show once animation reaches it
                  if (visible.length == _allPoints.length &&
                      _allPoints.length > 1)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _allPoints.last,
                          width: 28,
                          height: 28,
                          child: _MapPin(
                            color: const Color(0xFFFF6B00),
                            icon: AppIcons.motorcycle,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),

          // ── Bottom stats bar ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StatsBar(ride: ride),
          ),

          // ── Slide-up detail panel ──────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: _showDetails ? 0 : -340,
            left: 0,
            right: 0,
            child: _DetailPanel(ride: ride),
          ),
        ],
      ),
    );
  }
}

// ── Map Pin ───────────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});
  final Color      color;
  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: FaIcon(icon, color: Colors.white, size: 12),
      ),
    );
  }
}

// ── Stats Bar (always visible at bottom) ─────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.ride});
  final RideEntity ride;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BarStat(
                icon: AppIcons.route,
                label: 'history.distance'.tr(),
                value: '${ride.distanceKm.toStringAsFixed(2)} km',
                color: const Color(0xFFFF6B00),
              ),
              _Divider(),
              _BarStat(
                icon: AppIcons.timer,
                label: 'history.duration'.tr(),
                value: ride.durationFormatted,
                color: const Color(0xFF4FC3F7),
              ),
              _Divider(),
              _BarStat(
                icon: AppIcons.rupee,
                label: 'history.cost'.tr(),
                value: '₹${ride.cost.toStringAsFixed(2)}',
                color: const Color(0xFFFFD740),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white12);
}

class _BarStat extends StatelessWidget {
  const _BarStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final FaIconData icon;
  final String     label;
  final String     value;
  final Color      color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, color: color, size: 14),
        const SizedBox(height: 4),
        Text(value,
            style: AppFonts.heading(
                size: 14, color: color, letterSpacing: 0.5)),
        Text(label,
            style: AppFonts.caption(color: Colors.white38, size: 9)),
      ],
    );
  }
}

// ── Detail Panel (slide-up) ───────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.ride});
  final RideEntity ride;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text('history.details'.tr(),
                  style: AppFonts.sectionHeader(size: 12)),
              const SizedBox(height: 16),

              // 2-column grid of detail rows
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: AppIcons.maxSpeed,
                          label: 'history.max_speed'.tr(),
                          value:
                              '${ride.maxSpeedKmh.toStringAsFixed(1)} km/h',
                          color: const Color(0xFF69F0AE),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: AppIcons.avgSpeed,
                          label: 'history.avg_speed'.tr(),
                          value:
                              '${ride.avgSpeedKmh.toStringAsFixed(1)} km/h',
                          color: const Color(0xFF4FC3F7),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: AppIcons.fuel,
                          label: 'history.fuel_used'.tr(),
                          value:
                              '${(ride.distanceKm / 35).toStringAsFixed(3)} L',
                          color: const Color(0xFFFF6B00),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: AppIcons.route,
                          label: 'history.points'.tr(),
                          value: '${ride.pointCount} pts',
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: AppIcons.navigation,
                          label: 'history.start'.tr(),
                          value:
                              '${ride.startLat.toStringAsFixed(4)}, ${ride.startLng.toStringAsFixed(4)}',
                          color: const Color(0xFF69F0AE),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: AppIcons.flag,
                          label: 'history.end'.tr(),
                          value:
                              '${ride.endLat.toStringAsFixed(4)}, ${ride.endLng.toStringAsFixed(4)}',
                          color: const Color(0xFFFF6B00),
                        ),
                      ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final FaIconData icon;
  final String     label;
  final String     value;
  final Color      color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: FaIcon(icon, color: color, size: 12)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppFonts.caption(
                      color: Colors.white38, size: 9)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppFonts.body(
                      color: color,
                      size: 11,
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
