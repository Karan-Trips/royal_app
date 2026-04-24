import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/features/history/domain/ride_entity.dart';
import 'package:royal_app/features/history/presentation/providers/history_provider.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(rideHistoryNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFFF6B00),
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'history.title'.tr(),
          style: AppFonts.heading(size: 17, letterSpacing: 3),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF6B00), size: 20),
            onPressed: () =>
                ref.read(rideHistoryNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: AppFonts.body(color: Colors.redAccent),
          ),
        ),
        data: (rides) => rides.isEmpty
            ? _EmptyState()
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: rides.length,
                itemBuilder: (ctx, i) => _BentoCard(ride: rides[i]),
              ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(AppIcons.route, color: Color(0x33FF6B00), size: 64),
          const SizedBox(height: 16),
          Text(
            'history.empty'.tr(),
            style: AppFonts.body(color: Colors.white38, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'history.empty_sub'.tr(),
            style: AppFonts.caption(color: Colors.white24, size: 11),
          ),
        ],
      ),
    );
  }
}

// ── Bento Card ────────────────────────────────────────────────────────────────

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.ride});
  final RideEntity ride;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    final timeFmt = DateFormat('hh:mm a');

    return GestureDetector(
      onTap: () => context.goNamed('historyMap', extra: ride),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.10),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date / time ──────────────────────────────────────────
                Row(
                  children: [
                    const FaIcon(
                      AppIcons.timer,
                      color: Color(0x88FF6B00),
                      size: 10,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateFmt.format(ride.timestamp),
                      style: AppFonts.caption(
                        color: Colors.white70,
                        size: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeFmt.format(ride.timestamp),
                      style: AppFonts.caption(color: Colors.white38, size: 9),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Distance (hero stat) ─────────────────────────────────
                Text(
                  ride.distanceKm.toStringAsFixed(2),
                  style: AppFonts.hud(size: 30, color: const Color(0xFFFF6B00)),
                ),
                Text(
                  'km',
                  style: AppFonts.caption(
                    color: const Color(0xFFFF6B00),
                    size: 10,
                  ),
                ),

                const Spacer(),

                // ── Duration ─────────────────────────────────────────────
                _MiniStat(
                  icon: AppIcons.timer,
                  value: ride.durationFormatted,
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(height: 5),

                // ── Max speed ────────────────────────────────────────────
                _MiniStat(
                  icon: AppIcons.maxSpeed,
                  value: '${ride.maxSpeedKmh.toStringAsFixed(0)} km/h',
                  color: const Color(0xFF69F0AE),
                ),
                const SizedBox(height: 5),

                // ── Cost ─────────────────────────────────────────────────
                _MiniStat(
                  icon: AppIcons.rupee,
                  value: '₹${ride.cost.toStringAsFixed(2)}',
                  color: const Color(0xFFFFD740),
                ),

                const SizedBox(height: 10),

                // ── Tap hint ─────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Color(0x55FF6B00),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'history.replay'.tr(),
                      style: AppFonts.caption(
                        color: const Color(0x55FF6B00),
                        size: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final FaIconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, color: color, size: 10),
        const SizedBox(width: 5),
        Text(
          value,
          style: AppFonts.body(color: color, size: 11, weight: FontWeight.w600),
        ),
      ],
    );
  }
}
