import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/tracking/presentation/providers/tracking_provider.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16.r),
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
            blurRadius: 18.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            speed.toStringAsFixed(0),
            style: AppFonts.hud(
              size: 40,
              color: isActive ? const Color(0xFFFF6B00) : Colors.white54,
            ),
          ),
          Text('km/h', style: AppFonts.caption(letterSpacing: 1.5)),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(AppIcons.compass,
                    color: const Color(0xFFFF6B00), size: 9.sp),
                SizedBox(width: 4.w),
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
          if (isActive && tracking.maxSpeedKmh > 0) ...[
            SizedBox(height: 5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(AppIcons.maxSpeed, color: Colors.white38, size: 8.sp),
                  SizedBox(width: 4.w),
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
