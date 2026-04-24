import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/dashboard/providers/moto_provider.dart';
import 'package:royal_app/features/tracking/providers/tracking_provider.dart';
import 'package:royal_app/features/tracking/widgets/ride_fab.dart';

class RideStatsPanel extends StatelessWidget {
  const RideStatsPanel({
    super.key,
    required this.tracking,
    required this.stats,
  });

  final TrackingState tracking;
  final RideStats stats;

  @override
  Widget build(BuildContext context) {
    final isTracking = tracking.isTracking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isTracking
                ? const Color(0xFFFF6B00).withValues(alpha: 0.45)
                : Colors.white12,
            width: isTracking ? 1.5 : 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isTracking
                ? const Color(0xFFFF6B00).withValues(alpha: 0.1)
                : Colors.transparent,
            blurRadius: 28,
            spreadRadius: 4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Row 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                StatChip(
                  label: 'DISTANCE',
                  value: '${tracking.distanceKm.toStringAsFixed(2)} km',
                  icon: AppIcons.distance,
                  color: const Color(0xFFFF6B00),
                ),
                const SizedBox(width: 8),
                StatChip(
                  label: 'DURATION',
                  value: tracking.elapsedFormatted,
                  icon: AppIcons.timer,
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(width: 8),
                StatChip(
                  label: 'AVG SPEED',
                  value: '${tracking.avgSpeedKmh.toStringAsFixed(1)} km/h',
                  icon: AppIcons.avgSpeed,
                  color: const Color(0xFF69F0AE),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Row 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                StatChip(
                  label: 'FUEL USED',
                  value:
                      '${stats.fuelUsedLitres.toStringAsFixed(3)} L  •  ₹${stats.fuelUsedCost.toStringAsFixed(1)}',
                  icon: AppIcons.fuel,
                  color: Colors.amberAccent,
                  flex: 2,
                ),
                const SizedBox(width: 8),
                StatChip(
                  label: 'WALLET',
                  value: '₹${stats.fuelWallet.toStringAsFixed(0)}',
                  icon: AppIcons.wallet,
                  color: const Color(0xFFFFD740),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: RideFab(tracking: tracking),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────────────────────────────

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  final String label;
  final String value;
  final FaIconData icon;
  final Color color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: color, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppFonts.caption(letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppFonts.body(
                      size: 11,
                      weight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
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
