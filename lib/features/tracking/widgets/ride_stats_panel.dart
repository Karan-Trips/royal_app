import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final RideStats     stats;

  @override
  Widget build(BuildContext context) {
    final isTracking = tracking.isTracking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
            blurRadius: 28.r,
            spreadRadius: 4.r,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 36.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                StatChip(
                  label: 'DISTANCE',
                  value: '${tracking.distanceKm.toStringAsFixed(2)} km',
                  icon: AppIcons.distance,
                  color: const Color(0xFFFF6B00),
                ),
                SizedBox(width: 8.w),
                StatChip(
                  label: 'DURATION',
                  value: tracking.elapsedFormatted,
                  icon: AppIcons.timer,
                  color: const Color(0xFF4FC3F7),
                ),
                SizedBox(width: 8.w),
                StatChip(
                  label: 'AVG SPEED',
                  value: '${tracking.avgSpeedKmh.toStringAsFixed(1)} km/h',
                  icon: AppIcons.avgSpeed,
                  color: const Color(0xFF69F0AE),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
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
                SizedBox(width: 8.w),
                StatChip(
                  label: 'WALLET',
                  value: '₹${stats.fuelWallet.toStringAsFixed(0)}',
                  icon: AppIcons.wallet,
                  color: const Color(0xFFFFD740),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 24.h),
            child: RideFab(tracking: tracking),
          ),
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  final String     label;
  final String     value;
  final FaIconData icon;
  final Color      color;
  final int        flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: color, size: 12.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppFonts.caption(letterSpacing: 0.5)),
                  SizedBox(height: 2.h),
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
