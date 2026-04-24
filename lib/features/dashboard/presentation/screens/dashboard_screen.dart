import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_constants.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/core/services/connectivity_service.dart';
import 'package:royal_app/core/theme/theme_provider.dart';
import 'package:royal_app/core/utils/weather_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:royal_app/features/dashboard/presentation/providers/moto_provider.dart';
import 'package:royal_app/features/history/presentation/providers/history_provider.dart';
import 'package:royal_app/features/tracking/presentation/providers/tracking_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(rideStatsNotifierProvider);
    final isDark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final tempAsync = ref.watch(ahmedabadTempProvider);
    final onlineAsync = ref.watch(isOnlineProvider);
    final history = ref.watch(dailyHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, ref, isDark, tempAsync),
      body: Stack(
        children: [
          // ── Deep gradient background ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0000),
                  Color(0xFF000000),
                  Color(0xFF050505),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Red spotlight behind bike ─────────────────────────────────
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCC1100).withValues(alpha: 0.18),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Main scrollable content ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                onlineAsync.when(
                  data: (online) =>
                      online ? const SizedBox.shrink() : _OfflineBanner(),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _BikeSection(key: const ValueKey('bike_3d')),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _StatsGrid(stats: stats),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _DailyProgress(stats: stats),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _WeekChart(history: history),
                        ),

                        const SizedBox(height: 24),

                        _IgnitionButton(
                          onTap: () async {
                            await HapticFeedback.lightImpact();
                            await Future.delayed(
                              const Duration(milliseconds: 80),
                            );
                            await HapticFeedback.mediumImpact();
                            await Future.delayed(
                              const Duration(milliseconds: 80),
                            );
                            await HapticFeedback.heavyImpact();
                            if (!context.mounted) return;
                            await context.pushNamed('tracking');
                            // Save ride on return from tracking
                            if (!context.mounted) return;
                            final tracking = ref.read(trackingNotifierProvider);
                            if (tracking.points.length >= 2) {
                              await ref
                                  .read(rideHistoryNotifierProvider.notifier)
                                  .saveAndRefresh(
                                    points: tracking.points,
                                    distanceKm: tracking.distanceKm,
                                    cost:
                                        tracking.distanceKm *
                                        AppConstants.costPerKm,
                                    durationSeconds: tracking.elapsedSeconds,
                                    maxSpeedKmh: tracking.maxSpeedKmh,
                                    avgSpeedKmh: tracking.avgSpeedKmh,
                                  );
                            }
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AsyncValue<double> tempAsync,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          const FaIcon(AppIcons.motorcycle, color: Color(0xFFFF6B00), size: 18),
          const SizedBox(width: 10),
          Text(
            'MOTOSTACK',
            style: AppFonts.heading(
              size: 17,
              color: const Color(0xFFFF6B00),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
      actions: [
        tempAsync.when(
          data: (temp) => isHeatWarning(temp)
              ? Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        AppIcons.thermometer,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${temp.toStringAsFixed(0)}°C',
                        style: AppFonts.body(
                          size: 12,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),
        IconButton(
          icon: FaIcon(
            isDark ? AppIcons.lightMode : AppIcons.darkMode,
            size: 16,
          ),
          color: const Color(0xFFFF6B00),
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(themeNotifierProvider.notifier).toggle();
          },
        ),
        IconButton(
          icon: const FaIcon(AppIcons.history, size: 16),
          color: const Color(0xFFFF6B00),
          tooltip: 'history.title'.tr(),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.goNamed('history');
          },
        ),
        IconButton(
          icon: const FaIcon(AppIcons.speedometer, size: 16),
          color: const Color(0xFFFF6B00),
          tooltip: 'dashboard.mileage'.tr(),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.goNamed('mileage');
          },
        ),
        IconButton(
          icon: const FaIcon(AppIcons.settings, size: 16),
          color: const Color(0xFFFF6B00),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.goNamed('settings');
          },
        ),
      ],
    );
  }
}

// ── Offline Banner ─────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      child: Row(
        children: [
          const FaIcon(AppIcons.offline, color: Colors.orangeAccent, size: 12),
          const SizedBox(width: 8),
          Text(
            'Offline — showing cached data',
            style: AppFonts.caption(color: Colors.orangeAccent, size: 11),
          ),
        ],
      ),
    );
  }
}

// ── Bike Section ───────────────────────────────────────────────────────────────

class _BikeSection extends StatefulWidget {
  const _BikeSection({super.key});

  @override
  State<_BikeSection> createState() => _BikeSectionState();
}

class _BikeSectionState extends State<_BikeSection>
    with AutomaticKeepAliveClientMixin {
  final Flutter3DController _controller = Flutter3DController();

  static const _swatches = [
    (label: 'Supernova Blue', color: Color(0xFF1565C0)),
    (label: 'Custom Red', color: Color(0xFFCC1100)),
    (label: 'Stellar Black', color: Color(0xFF1A1A1A)),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (ctx, ref, _) {
        final activeColor = ref.watch(bikeColorNotifierProvider);
        return Column(
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Flutter3DViewer(
                    src: 'assets/models/meteor.glb',
                    controller: _controller,
                    progressBarColor: const Color(0xFFFF6B00),
                  ),

                  // Bottom fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),

                  // RE branding
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROYAL ENFIELD',
                          style: AppFonts.caption(
                            color: Colors.white30,
                            size: 8,
                            letterSpacing: 3.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF6B00), Color(0xFFFF2200)],
                          ).createShader(bounds),
                          child: Text(
                            'METEOR 350',
                            style: AppFonts.heading(
                              size: 20,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Text(
                          'SUPERNOVA RED',
                          style: AppFonts.caption(
                            color: Colors.white38,
                            size: 9,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Drag hint
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        const FaIcon(
                          AppIcons.route,
                          color: Color(0x33FFFFFF),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Drag to rotate',
                          style: AppFonts.caption(
                            color: const Color(0x33FFFFFF),
                            size: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Color swatches ──────────────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                itemCount: _swatches.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final s = _swatches[i];
                  final isActive = activeColor == s.color;
                  return GestureDetector(
                    onTap: () => ref
                        .read(bikeColorNotifierProvider.notifier)
                        .changeColor(s.color, _controller),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: isActive ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? s.color
                              : s.color.withValues(alpha: 0.3),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.label,
                            style: AppFonts.caption(
                              size: 9,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Stats Grid ─────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final RideStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassCard(
                label: 'dashboard.today'.tr(),
                value: '${stats.todayDistance.toStringAsFixed(2)} km',
                icon: AppIcons.timer,
                accent: const Color(0xFFFF6B00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassCard(
                label: 'dashboard.total'.tr(),
                value: '${stats.totalDistance.toStringAsFixed(1)} km',
                icon: AppIcons.route,
                accent: const Color(0xFF4FC3F7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GlassCard(
                label: 'dashboard.fuel_used'.tr(),
                value:
                    '${stats.fuelUsedLitres.toStringAsFixed(3)} L\n₹${stats.fuelUsedCost.toStringAsFixed(1)}',
                icon: AppIcons.fuel,
                accent: const Color(0xFF69F0AE),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassCard(
                label: 'dashboard.balance'.tr(),
                value: '₹${stats.fuelWallet.toStringAsFixed(0)}',
                icon: AppIcons.wallet,
                accent: const Color(0xFFFFD740),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final FaIconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: FaIcon(icon, color: accent, size: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.caption(size: 10, letterSpacing: 0.4),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppFonts.body(
                    color: accent,
                    weight: FontWeight.bold,
                    size: 13,
                  ).copyWith(height: 1.3),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily Progress ─────────────────────────────────────────────────────────────

class _DailyProgress extends StatelessWidget {
  const _DailyProgress({required this.stats});
  final RideStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.dailyProgress * 100).toInt();
    final color = stats.dailyGoalMet
        ? const Color(0xFF69F0AE)
        : const Color(0xFFFF6B00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dashboard.daily_goal'.tr(namedArgs: {'percent': '$pct'}),
                style: AppFonts.caption(size: 11),
              ),
              if (stats.dailyGoalMet)
                Row(
                  children: [
                    FaIcon(AppIcons.check, color: color, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      'Goal Met!',
                      style: AppFonts.body(color: color, size: 11),
                    ),
                  ],
                )
              else
                Text(
                  '${stats.todayDistance.toStringAsFixed(1)} / ${AppConstants.dailyTargetKm.toStringAsFixed(0)} km',
                  style: AppFonts.caption(size: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.dailyProgress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 7-Day Bar Chart ────────────────────────────────────────────────────────────

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.history});
  final Map<String, double> history;

  @override
  Widget build(BuildContext context) {
    final entries = history.entries.toList();
    final maxY = entries.isEmpty
        ? AppConstants.dailyTargetKm
        : entries
                  .map((e) => e.value)
                  .reduce((a, b) => a > b ? a : b)
                  .clamp(AppConstants.dailyTargetKm, double.infinity) *
              1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(AppIcons.chart, color: Color(0xFFFF6B00), size: 14),
              const SizedBox(width: 6),
              Text('7-DAY DISTANCE', style: AppFonts.sectionHeader()),
              const Spacer(),
              Text(
                '${AppConstants.dailyTargetKm.toStringAsFixed(0)} km goal',
                style: AppFonts.caption(size: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: AppConstants.dailyTargetKm,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: v == AppConstants.dailyTargetKm
                        ? const Color(0xFFFF6B00).withValues(alpha: 0.4)
                        : Colors.white10,
                    strokeWidth: v == AppConstants.dailyTargetKm ? 1.5 : 0.5,
                    dashArray: v == AppConstants.dailyTargetKm ? [4, 4] : null,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = entries[idx].key.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${parts[2]}/${parts[1]}',
                            style: AppFonts.caption(size: 8),
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                barGroups: List.generate(entries.length, (i) {
                  final km = entries[i].value;
                  final metGoal = km >= AppConstants.dailyTargetKm;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: km == 0 ? 0.3 : km,
                        width: 18,
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: metGoal
                              ? [
                                  const Color(0xFF00C853),
                                  const Color(0xFF69F0AE),
                                ]
                              : [
                                  const Color(0xFF8B1A00),
                                  const Color(0xFFFF6B00),
                                ],
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A1A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final km = entries[groupIndex].value;
                      return BarTooltipItem(
                        '${km.toStringAsFixed(1)} km',
                        AppFonts.body(
                          color: const Color(0xFFFF6B00),
                          weight: FontWeight.bold,
                          size: 11,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ignition Button ────────────────────────────────────────────────────────────

class _IgnitionButton extends StatefulWidget {
  const _IgnitionButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_IgnitionButton> createState() => _IgnitionButtonState();
}

class _IgnitionButtonState extends State<_IgnitionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _glow = Tween(
      begin: 18.0,
      end: 36.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, child) => GestureDetector(
        onTap: widget.onTap,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFF5500), Color(0xFF8B0000)],
                center: Alignment(-0.25, -0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4400).withValues(alpha: 0.6),
                  blurRadius: _glow.value,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.2),
                  blurRadius: _glow.value * 2.2,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(AppIcons.ignition, color: Colors.white, size: 36),
                const SizedBox(height: 6),
                Text(
                  'dashboard.ignition'.tr(),
                  style: AppFonts.caption(
                    color: Colors.white,
                    size: 9,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
