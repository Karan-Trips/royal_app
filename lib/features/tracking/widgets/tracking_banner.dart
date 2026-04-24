import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          FaIcon(icon, color: iconColor, size: 12),
          const SizedBox(width: 8),
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
