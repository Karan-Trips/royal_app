import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/tracking/providers/tracking_provider.dart';

String bearingLabel(double deg) {
  const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return labels[((deg + 22.5) / 45).floor() % 8];
}

class SpeedHud extends StatelessWidget {
  const SpeedHud({super.key, required this.tracking});
  final TrackingState tracking;

  @override
  Widget build(BuildContext context) {
    final speed    = tracking.currentSpeedKmh;
    final isActive = tracking.isTracking;
    final bearing  = bearingLabel(tracking.heading);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF6B00).withValues(alpha: 0.5)
              : Colors.white12,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFFFF6B00).withValues(alpha: 0.18)
                : Colors.transparent,
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed number — Rajdhani bold
          Text(
            speed.toStringAsFixed(0),
            style: AppFonts.hud(
              size: 40,
              color: isActive ? const Color(0xFFFF6B00) : Colors.white54,
            ),
          ),
          Text('km/h', style: AppFonts.caption(letterSpacing: 1.5)),

          // Bearing badge
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(AppIcons.compass,
                    color: Color(0xFFFF6B00), size: 9),
                const SizedBox(width: 4),
                Text(
                  bearing,
                  style: AppFonts.body(
                    size: 12,
                    weight: FontWeight.bold,
                    color: const Color(0xFFFF6B00),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Max speed badge
          if (isActive && tracking.maxSpeedKmh > 0) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(AppIcons.maxSpeed,
                      color: Colors.white38, size: 8),
                  const SizedBox(width: 4),
                  Text(
                    'MAX ${tracking.maxSpeedKmh.toStringAsFixed(0)}',
                    style: AppFonts.caption(letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
