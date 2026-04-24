import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

class _GateScreenState extends ConsumerState<GateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appGateNotifierProvider.notifier).authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(appGateNotifierProvider);

    ref.listen(appGateNotifierProvider, (prev, next) {
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
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _BrandMark(),
                const SizedBox(height: 56),
                _StatusArea(gate: gate),
                const SizedBox(height: 40),
                _ActionButton(gate: gate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Brand Mark ─────────────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF6B00), width: 2),
            color: const Color(0xFF0F0F0F),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const FaIcon(
            AppIcons.motorcycle,
            color: Color(0xFFFF6B00),
            size: 40,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'app_name'.tr(),
          style: AppFonts.heading(size: 30, letterSpacing: 7),
        ),
        const SizedBox(height: 6),
        Text(
          'bike_subtitle'.tr(),
          style: AppFonts.caption(size: 13, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

// ── Status Area ────────────────────────────────────────────────────────────────

class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.gate});
  final AppGateState gate;

  @override
  Widget build(BuildContext context) {
    return switch (gate.status) {
      GateStatus.idle           => const SizedBox.shrink(),
      GateStatus.authenticating => _BusyBlock(
          label: 'gate.verifying'.tr(),
          sublabel: gate.biometricLabel,
        ),
      GateStatus.locating       => _BusyBlock(label: 'gate.locating'.tr()),
      GateStatus.authFailed     => _ErrorBlock(
          icon: AppIcons.fingerprint,
          message: gate.errorMessage ?? 'gate.auth_failed'.tr(),
        ),
      GateStatus.locationDenied => _ErrorBlock(
          icon: AppIcons.locationOff,
          message: gate.errorMessage ?? 'gate.location_denied'.tr(),
        ),
      GateStatus.ready          => const SizedBox.shrink(),
    };
  }
}

class _BusyBlock extends StatelessWidget {
  const _BusyBlock({required this.label, this.sublabel});
  final String  label;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(color: Color(0xFFFF6B00)),
        const SizedBox(height: 16),
        Text(label, style: AppFonts.body(color: Colors.white54)),
        if (sublabel != null) ...[
          const SizedBox(height: 4),
          Text(
            sublabel!,
            style: AppFonts.caption(
              color: const Color(0xFFFF6B00),
              size: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.icon, required this.message});
  final FaIconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FaIcon(icon, color: Colors.redAccent, size: 38),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppFonts.body(color: Colors.white60, size: 13),
        ),
      ],
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────────

class _ActionButton extends ConsumerWidget {
  const _ActionButton({required this.gate});
  final AppGateState gate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy =
        gate.status == GateStatus.authenticating ||
        gate.status == GateStatus.locating ||
        gate.status == GateStatus.ready;

    if (isBusy) return const SizedBox.shrink();

    final isLocationIssue = gate.status == GateStatus.locationDenied;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: FaIcon(
          isLocationIssue ? AppIcons.locationOff : AppIcons.fingerprint,
          size: 16,
        ),
        label: Text(
          isLocationIssue
              ? 'gate.retry_location'.tr()
              : 'gate.authenticate'.tr(),
          style: AppFonts.button(),
        ),
        onPressed: () =>
            ref.read(appGateNotifierProvider.notifier).authenticate(),
      ),
    );
  }
}
