import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // Outer slow pulse ring
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // Inner icon breathe
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathScale;

  // Shake on error
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();

    // Pulse ring — expands outward and fades
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseScale = Tween(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    // Icon breathe — subtle scale in/out
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _breathScale = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );

    // Shake — horizontal jitter on error
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeOffset = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Kick off auth automatically on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appGateNotifierProvider.notifier).authenticate();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _breathCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // Called whenever gate state changes
  void _onStateChange(AppGateState? prev, AppGateState next) {
    // Navigate to dashboard when fully ready
    if (next.status == GateStatus.ready) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, _) => const DashboardScreen(),
          transitionsBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }

    // Shake + haptic on any failure
    if (next.status == GateStatus.authFailed ||
        next.status == GateStatus.locationDenied) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(appGateNotifierProvider);

    ref.listen(appGateNotifierProvider, _onStateChange);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background radial glow ──────────────────────────────────────
          Center(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentFor(gate.status).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App brand
                  _AppBrand(),

                  const Spacer(flex: 2),

                  // Animated biometric icon
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseCtrl,
                      _breathCtrl,
                      _shakeCtrl,
                    ]),
                    builder: (ctx, _) {
                      // Shake offset — sinusoidal horizontal jitter
                      final shake = math.sin(_shakeOffset.value * math.pi * 6) *
                          10 *
                          (1 - _shakeOffset.value);

                      return Transform.translate(
                        offset: Offset(shake, 0),
                        child: _BiometricIcon(
                          status: gate.status,
                          pulseScale: _pulseScale.value,
                          pulseOpacity: _pulseOpacity.value,
                          breathScale: _breathScale.value,
                          label: gate.biometricLabel,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Status message block
                  _StatusMessage(gate: gate),

                  const SizedBox(height: 32),

                  // Step indicator — Auth → GPS → Enter
                  _StepIndicator(status: gate.status),

                  const Spacer(flex: 2),

                  // Action button (only shown on idle / error states)
                  _ActionButton(gate: gate),

                  const SizedBox(height: 32),

                  // Security note at the bottom
                  _SecurityNote(),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Returns the accent colour for the current gate status
  Color _accentFor(GateStatus status) {
    return switch (status) {
      GateStatus.authFailed     => Colors.redAccent,
      GateStatus.locationDenied => Colors.orangeAccent,
      GateStatus.ready          => const Color(0xFF69F0AE),
      _                         => const Color(0xFFFF6B00),
    };
  }
}

// ── App Brand ──────────────────────────────────────────────────────────────────

class _AppBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'app_name'.tr(),
          style: AppFonts.heading(size: 28, letterSpacing: 6, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'bike_subtitle'.tr(),
          style: AppFonts.caption(
            size: 11,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Biometric Icon with pulse ring ─────────────────────────────────────────────

class _BiometricIcon extends StatelessWidget {
  const _BiometricIcon({
    required this.status,
    required this.pulseScale,
    required this.pulseOpacity,
    required this.breathScale,
    this.label,
  });

  final GateStatus status;
  final double     pulseScale;
  final double     pulseOpacity;
  final double     breathScale;
  final String?    label;

  @override
  Widget build(BuildContext context) {
    // Pick icon and colours based on current status
    final (icon, iconColor, ringColor) = switch (status) {
      GateStatus.authFailed     => (AppIcons.lock,        Colors.redAccent,          Colors.redAccent),
      GateStatus.locationDenied => (AppIcons.locationOff, Colors.orangeAccent,       Colors.orangeAccent),
      GateStatus.locating       => (AppIcons.locate,      const Color(0xFF4FC3F7),   const Color(0xFF4FC3F7)),
      GateStatus.ready          => (AppIcons.check,       const Color(0xFF69F0AE),   const Color(0xFF69F0AE)),
      _                         => (AppIcons.fingerprint, const Color(0xFFFF6B00),   const Color(0xFFFF6B00)),
    };

    // Only animate the pulse ring when actively authenticating
    final showPulse = status == GateStatus.authenticating ||
        status == GateStatus.idle;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer expanding pulse ring
          if (showPulse)
            Transform.scale(
              scale: pulseScale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ringColor.withValues(alpha: pulseOpacity),
                    width: 2,
                  ),
                ),
              ),
            ),

          // Middle static ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
          ),

          // Inner filled circle with icon
          Transform.scale(
            scale: showPulse ? breathScale : 1.0,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F0F0F),
                border: Border.all(color: ringColor.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: status == GateStatus.locating
                  // Show spinner while fetching GPS
                  ? Padding(
                      padding: const EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                        color: iconColor,
                        strokeWidth: 2.5,
                      ),
                    )
                  : FaIcon(icon, color: iconColor, size: 42),
            ),
          ),

          // Biometric type label below icon (e.g. "Face ID")
          if (label != null &&
              (status == GateStatus.idle ||
                  status == GateStatus.authenticating))
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  label!,
                  style: AppFonts.caption(
                    size: 10,
                    color: const Color(0xFFFF6B00),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Status Message ─────────────────────────────────────────────────────────────

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.gate});
  final AppGateState gate;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, titleColor) = switch (gate.status) {
      GateStatus.idle => (
          'Biometric Required',
          'Touch the sensor or use Face ID\nto access MotoStack',
          Colors.white,
        ),
      GateStatus.authenticating => (
          'Verifying Identity',
          gate.biometricLabel != null
              ? 'Waiting for ${gate.biometricLabel}…'
              : 'gate.verifying'.tr(),
          Colors.white,
        ),
      GateStatus.locating => (
          'Getting Location',
          'gate.locating'.tr(),
          const Color(0xFF4FC3F7),
        ),
      GateStatus.authFailed => (
          'Authentication Failed',
          gate.errorMessage ?? 'gate.auth_failed'.tr(),
          Colors.redAccent,
        ),
      GateStatus.locationDenied => (
          'Location Required',
          gate.errorMessage ?? 'gate.location_denied'.tr(),
          Colors.orangeAccent,
        ),
      GateStatus.ready => (
          'All Good!',
          'Opening MotoStack…',
          const Color(0xFF69F0AE),
        ),
    };

    return Column(
      children: [
        Text(
          title,
          style: AppFonts.heading(
            size: 22,
            color: titleColor,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: AppFonts.body(
            size: 13,
            color: Colors.white54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────────
// Shows three steps: Authenticate → Location → Enter
// Each step lights up as the gate progresses.

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.status});
  final GateStatus status;

  @override
  Widget build(BuildContext context) {
    // Map each status to how many steps are "done"
    final completedSteps = switch (status) {
      GateStatus.idle           => 0,
      GateStatus.authenticating => 0,
      GateStatus.authFailed     => 0,
      GateStatus.locating       => 1,
      GateStatus.locationDenied => 1,
      GateStatus.ready          => 3,
    };

    // Which step is currently active (in-progress)
    final activeStep = switch (status) {
      GateStatus.authenticating => 0,
      GateStatus.locating       => 1,
      GateStatus.ready          => 2,
      _                         => -1,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Step(
          icon: AppIcons.fingerprint,
          label: 'Auth',
          done: completedSteps > 0,
          active: activeStep == 0,
        ),
        _StepConnector(lit: completedSteps > 0),
        _Step(
          icon: AppIcons.locate,
          label: 'GPS',
          done: completedSteps > 1,
          active: activeStep == 1,
        ),
        _StepConnector(lit: completedSteps > 1),
        _Step(
          icon: AppIcons.motorcycle,
          label: 'Ride',
          done: completedSteps > 2,
          active: activeStep == 2,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.label,
    required this.done,
    required this.active,
  });

  final FaIconData icon;
  final String     label;
  final bool       done;
  final bool       active;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF69F0AE)   // completed → green
        : active
            ? const Color(0xFFFF6B00) // in-progress → orange
            : Colors.white24;         // pending → dim

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: FaIcon(icon, color: color, size: 14),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppFonts.caption(size: 9, color: color, letterSpacing: 1),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.lit});
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 16),
      color: lit ? const Color(0xFF69F0AE) : Colors.white12,
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────────

class _ActionButton extends ConsumerWidget {
  const _ActionButton({required this.gate});
  final AppGateState gate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide button while any async work is in progress or app is ready
    final isBusy = gate.status == GateStatus.authenticating ||
        gate.status == GateStatus.locating ||
        gate.status == GateStatus.ready;

    if (isBusy) return const SizedBox.shrink();

    final isLocationIssue = gate.status == GateStatus.locationDenied;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLocationIssue
              ? Colors.orangeAccent
              : const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: FaIcon(
          isLocationIssue ? AppIcons.locationOff : AppIcons.fingerprint,
          size: 16,
        ),
        label: Text(
          isLocationIssue
              ? 'gate.retry_location'.tr()
              : gate.status == GateStatus.idle
                  ? 'gate.authenticate'.tr()
                  : 'Try Again',
          style: AppFonts.button(size: 15),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(appGateNotifierProvider.notifier).authenticate();
        },
      ),
    );
  }
}

// ── Security Note ──────────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(AppIcons.lock, color: Colors.white24, size: 10),
        const SizedBox(width: 6),
        Text(
          'Biometric data never leaves your device',
          style: AppFonts.caption(size: 10, color: Colors.white24),
        ),
      ],
    );
  }
}
