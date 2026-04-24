import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/core/providers/app_gate_provider.dart';
import 'package:royal_app/features/dashboard/screens/dashboard_screen.dart';

class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key});

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowOpacity;
  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeOffset;

  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowOpacity = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _showAuthSheet());
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _showAuthSheet() {
    if (_sheetOpen) return;
    _sheetOpen = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _AuthSheet(
        onDone: () {
          _sheetOpen = false;
          Navigator.of(context).pop();
        },
      ),
    ).then((_) => _sheetOpen = false);

    ref.read(appGateNotifierProvider.notifier).authenticate();
  }

  void _onStateChange(AppGateState? prev, AppGateState next) {
    if (next.status == GateStatus.ready) {
      if (_sheetOpen) {
        _sheetOpen = false;
        Navigator.of(context).pop();
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => const DashboardScreen(),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }

    if (next.status == GateStatus.authFailed ||
        next.status == GateStatus.locationDenied) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appGateNotifierProvider, _onStateChange);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _AnimatedBackground(
            rotateCtrl: _rotateCtrl,
            glowOpacity: _glowOpacity,
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (ctx, child) {
                final shake = math.sin(_shakeOffset.value * math.pi * 6) *
                    8 *
                    (1 - _shakeOffset.value);
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const _SplashBrand(),
                  const Spacer(flex: 1),
                  const _LockBadge(),
                  const Spacer(flex: 3),
                  const _SecurityNote(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Background ────────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.rotateCtrl,
    required this.glowOpacity,
  });

  final AnimationController rotateCtrl;
  final Animation<double>   glowOpacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotateCtrl, glowOpacity]),
      builder: (ctx, _) => Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0000), Color(0xFF000000), Color(0xFF050510)],
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: glowOpacity.value,
              child: Container(
                width: 300.w,
                height: 300.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B00).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: rotateCtrl.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(0.75.sw, 0.75.sw),
                painter: _OrbitRingPainter(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: -rotateCtrl.value * 2 * math.pi * 0.6,
              child: CustomPaint(
                size: Size(0.92.sw, 0.92.sw),
                painter: _OrbitRingPainter(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.06),
                  dashCount: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({required this.color, this.dashCount = 12});
  final Color color;
  final int   dashCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final cx         = size.width / 2;
    final cy         = size.height / 2;
    final r          = cx - 2;
    final dashAngle  = (2 * math.pi) / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      final end   = start + dashAngle * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, end - start, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) => old.color != color;
}

// ── Splash Brand ───────────────────────────────────────────────────────────────

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88.w,
          height: 88.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F0F0F),
            border: Border.all(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                blurRadius: 28.r,
                spreadRadius: 4.r,
              ),
            ],
          ),
          child: Center(
            child: FaIcon(AppIcons.motorcycle,
                color: const Color(0xFFFF6B00), size: 36.sp),
          ),
        ),
        SizedBox(height: 20.h),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFFAA00)],
          ).createShader(bounds),
          child: Text(
            'app_name'.tr(),
            style: AppFonts.heading(size: 32, color: Colors.white, letterSpacing: 7),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'bike_subtitle'.tr(),
          style: AppFonts.caption(size: 11, color: Colors.white30, letterSpacing: 2),
        ),
      ],
    );
  }
}

// ── Lock Badge ─────────────────────────────────────────────────────────────────

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(AppIcons.lock, color: const Color(0xFFFF6B00), size: 12.sp),
          SizedBox(width: 8.w),
          Text(
            'Biometric authentication required',
            style: AppFonts.caption(size: 11, color: Colors.white54, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ── Security Note ──────────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(AppIcons.fingerprint, color: Colors.white12, size: 10.sp),
        SizedBox(width: 6.w),
        Text(
          'Biometric data never leaves your device',
          style: AppFonts.caption(size: 10, color: Colors.white24),
        ),
      ],
    );
  }
}

// ── Auth Sheet ─────────────────────────────────────────────────────────────────

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet({required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseScale = Tween(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gate     = ref.watch(appGateNotifierProvider);
    final isActive = gate.status == GateStatus.authenticating ||
        gate.status == GateStatus.idle;

    final (icon, color, title, subtitle) = switch (gate.status) {
      GateStatus.idle || GateStatus.authenticating => (
          AppIcons.fingerprint,
          const Color(0xFFFF6B00),
          gate.biometricLabel ?? 'Biometric',
          'Touch sensor or use ${gate.biometricLabel ?? 'Face ID'} to continue',
        ),
      GateStatus.locating => (
          AppIcons.locate,
          const Color(0xFF4FC3F7),
          'Getting Location',
          'gate.locating'.tr(),
        ),
      GateStatus.authFailed => (
          AppIcons.lock,
          Colors.redAccent,
          'Authentication Failed',
          gate.errorMessage ?? 'gate.auth_failed'.tr(),
        ),
      GateStatus.locationDenied => (
          AppIcons.locationOff,
          Colors.orangeAccent,
          'Location Required',
          gate.errorMessage ?? 'gate.location_denied'.tr(),
        ),
      GateStatus.ready => (
          AppIcons.check,
          const Color(0xFF69F0AE),
          'Verified!',
          'Opening MotoStack…',
        ),
    };

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 32.r,
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),

            // Animated icon
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (ctx, _) => Transform.scale(
                scale: isActive ? _pulseScale.value : 1.0,
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 20.r,
                        spreadRadius: 2.r,
                      ),
                    ],
                  ),
                  child: gate.status == GateStatus.locating
                      ? Padding(
                          padding: EdgeInsets.all(20.r),
                          child: CircularProgressIndicator(
                            color: color, strokeWidth: 2,
                          ),
                        )
                      : Center(
                          child: FaIcon(icon, color: color, size: 30.sp),
                        ),
                ),
              ),
            ),

            SizedBox(height: 18.h),
            Text(title,
                style: AppFonts.heading(size: 18, color: color, letterSpacing: 1)),
            SizedBox(height: 8.h),
            Text(subtitle,
                style: AppFonts.body(size: 13, color: Colors.white54),
                textAlign: TextAlign.center),
            SizedBox(height: 24.h),

            _SheetStepDots(status: gate.status),

            if (gate.status == GateStatus.authFailed ||
                gate.status == GateStatus.locationDenied ||
                gate.status == GateStatus.idle) ...[
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: FaIcon(
                    gate.status == GateStatus.locationDenied
                        ? AppIcons.locationOff
                        : AppIcons.fingerprint,
                    size: 15.sp,
                  ),
                  label: Text(
                    gate.status == GateStatus.locationDenied
                        ? 'gate.retry_location'.tr()
                        : gate.status == GateStatus.idle
                            ? 'gate.authenticate'.tr()
                            : 'Try Again',
                    style: AppFonts.button(size: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(appGateNotifierProvider.notifier).authenticate();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sheet Step Dots ────────────────────────────────────────────────────────────

class _SheetStepDots extends StatelessWidget {
  const _SheetStepDots({required this.status});
  final GateStatus status;

  @override
  Widget build(BuildContext context) {
    final done = switch (status) {
      GateStatus.idle ||
      GateStatus.authenticating ||
      GateStatus.authFailed         => 0,
      GateStatus.locating ||
      GateStatus.locationDenied     => 1,
      GateStatus.ready              => 3,
    };
    final active = switch (status) {
      GateStatus.authenticating => 0,
      GateStatus.locating       => 1,
      GateStatus.ready          => 2,
      _                         => -1,
    };

    Color dotColor(int i) {
      if (i < done)    return const Color(0xFF69F0AE);
      if (i == active) return const Color(0xFFFF6B00);
      return Colors.white12;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(color: dotColor(0), label: 'Auth'),
        _DotLine(lit: done > 0),
        _Dot(color: dotColor(1), label: 'GPS'),
        _DotLine(lit: done > 1),
        _Dot(color: dotColor(2), label: 'Ride'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(height: 4.h),
        Text(label, style: AppFonts.caption(size: 8, color: color)),
      ],
    );
  }
}

class _DotLine extends StatelessWidget {
  const _DotLine({required this.lit});
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32.w,
      height: 1.h,
      margin: EdgeInsets.only(bottom: 14.h),
      color: lit ? const Color(0xFF69F0AE) : Colors.white12,
    );
  }
}
