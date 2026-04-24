import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/tracking/providers/tracking_provider.dart';

class RideFab extends ConsumerWidget {
  const RideFab({super.key, required this.tracking});
  final TrackingState tracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTracking = tracking.isTracking;

    return GestureDetector(
      onTap: () async {
        final notifier = ref.read(trackingNotifierProvider.notifier);
        if (isTracking) {
          await HapticFeedback.heavyImpact();
          notifier.stopTracking();
        } else {
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          await HapticFeedback.heavyImpact();
          notifier.startTracking();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTracking
                ? [Colors.red.shade900, Colors.red.shade700]
                : [const Color(0xFFFF4500), const Color(0xFFFF6B00)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: (isTracking ? Colors.red : const Color(0xFFFF6B00))
                  .withValues(alpha: 0.45),
              blurRadius: 18.r,
              spreadRadius: 2.r,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              isTracking ? AppIcons.stop : AppIcons.play,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              isTracking
                  ? 'tracking.stop_ride'.tr()
                  : 'tracking.start_ride'.tr(),
              style: AppFonts.button(),
            ),
          ],
        ),
      ),
    );
  }
}
