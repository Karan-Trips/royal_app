import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';

class TrackingBanner extends StatelessWidget {
  const TrackingBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final Color      color;
  final FaIconData icon;
  final Color      iconColor;
  final String     text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
      child: Row(
        children: [
          FaIcon(icon, color: iconColor, size: 12.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppFonts.caption(color: iconColor, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
