import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/tracking/presentation/widgets/map_style.dart';

class MapIconButton extends StatelessWidget {
  const MapIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  final FaIconData   icon;
  final VoidCallback onTap;
  final bool         active;
  final String?      tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFF6B00).withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: active ? const Color(0xFFFF6B00) : Colors.white12,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                    blurRadius: 10.r,
                    spreadRadius: 1.r,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: active ? Colors.white : Colors.white54,
            size: 16.sp,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final MapStyle                current;
  final ValueChanged<MapStyle>  onChanged;

  @override
  Widget build(BuildContext context) {
    return MapIconButton(
      icon: current.faIcon,
      tooltip: 'Map style',
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _MapStyleSheet(current: current, onChanged: onChanged),
    );
  }
}

class _MapStyleSheet extends StatelessWidget {
  const _MapStyleSheet({required this.current, required this.onChanged});

  final MapStyle               current;
  final ValueChanged<MapStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 3.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Text('MAP STYLE', style: AppFonts.sectionHeader()),
          SizedBox(height: 16.h),
          Row(
            children: MapStyle.values.map((s) {
              final selected = s == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    onChanged(s);
                    context.pop();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF6B00).withValues(alpha: 0.15)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFF6B00)
                            : Colors.white12,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          s.faIcon,
                          color: selected
                              ? const Color(0xFFFF6B00)
                              : Colors.white38,
                          size: 22.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          s.label,
                          style: AppFonts.caption(
                            color: selected
                                ? const Color(0xFFFF6B00)
                                : Colors.white38,
                            size: 10,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
