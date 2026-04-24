import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_constants.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/core/models/fuel_entry.dart';
import 'package:royal_app/features/mileage/providers/mileage_provider.dart';

class MileageScreen extends ConsumerStatefulWidget {
  const MileageScreen({super.key});

  @override
  ConsumerState<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends ConsumerState<MileageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litresCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(
    text: AppConstants.petrolPricePerLitre.toString(),
  );

  @override
  void dispose() {
    _litresCtrl.dispose();
    _kmCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    ref
        .read(mileageNotifierProvider.notifier)
        .addEntry(
          litresFilled: double.parse(_litresCtrl.text),
          kmDriven: double.parse(_kmCtrl.text),
          pricePerLitre: double.parse(_priceCtrl.text),
        );
    _litresCtrl.clear();
    _kmCtrl.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('mileage.entry_saved'.tr()),
        backgroundColor: const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(mileageNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text('mileage.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryRow(stats: stats),
          const SizedBox(height: 16),

          if (stats.hasEntries) _MileageTrendChart(entries: stats.entries),
          if (stats.hasEntries) const SizedBox(height: 16),

          _InputForm(
            formKey: _formKey,
            litresCtrl: _litresCtrl,
            kmCtrl: _kmCtrl,
            priceCtrl: _priceCtrl,
            onSubmit: _submit,
          ),
          const SizedBox(height: 24),

          if (stats.hasEntries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'mileage.history'.tr().toUpperCase(),
                style: AppFonts.sectionHeader(),
              ),
            ),
            ...stats.entries.map(
              (e) => _EntryTile(
                entry: e,
                onDelete: () {
                  HapticFeedback.lightImpact();
                  ref.read(mileageNotifierProvider.notifier).deleteEntry(e.id);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary Row ────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});
  final MileageStats stats;

  @override
  Widget build(BuildContext context) {
    final mileageColor = stats.avgMileage >= AppConstants.factoryMileage
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0A00), Color(0xFF0D0D0D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                'mileage.avg_mileage'.tr(),
                style: AppFonts.caption(size: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stats.hasEntries
                        ? stats.avgMileage.toStringAsFixed(1)
                        : '--',
                    style: AppFonts.hud(
                      size: 48,
                      color: mileageColor,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      'km/l',
                      style: AppFonts.body(color: Colors.white54, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(AppIcons.info, color: Colors.white38, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'mileage.factory_claim'.tr(
                      namedArgs: {
                        'km': AppConstants.factoryMileage.toStringAsFixed(0),
                      },
                    ),
                    style: AppFonts.caption(size: 11),
                  ),
                  if (stats.hasEntries) ...[
                    const SizedBox(width: 8),
                    _DiffBadge(
                      diff: stats.avgMileage - AppConstants.factoryMileage,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                label: 'mileage.total_litres'.tr(),
                value: stats.hasEntries
                    ? '${stats.totalLitres.toStringAsFixed(2)} L'
                    : '--',
                icon: AppIcons.fuel,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniCard(
                label: 'mileage.total_cost'.tr(),
                value: stats.hasEntries
                    ? '₹${stats.totalCost.toStringAsFixed(0)}'
                    : '--',
                icon: AppIcons.rupee,
                color: Colors.amberAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniCard(
                label: 'mileage.total_km'.tr(),
                value: stats.hasEntries
                    ? '${stats.totalKm.toStringAsFixed(0)} km'
                    : '--',
                icon: AppIcons.route,
                color: Colors.greenAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.diff});
  final double diff;

  @override
  Widget build(BuildContext context) {
    final positive = diff >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (positive ? Colors.green : Colors.red).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${positive ? '+' : ''}${diff.toStringAsFixed(1)} km/l',
        style: AppFonts.caption(
          color: positive ? Colors.greenAccent : Colors.redAccent,
          size: 10,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final FaIconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.body(
              color: Colors.white,
              weight: FontWeight.bold,
              size: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.caption(size: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Mileage Trend Line Chart ───────────────────────────────────────────────────

class _MileageTrendChart extends StatelessWidget {
  const _MileageTrendChart({required this.entries});
  final List<FuelEntry> entries;

  @override
  Widget build(BuildContext context) {
    final data = entries.reversed.take(8).toList().reversed.toList();
    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].actualMileage),
    );
    final maxY =
        data.map((e) => e.actualMileage).reduce((a, b) => a > b ? a : b) * 1.25;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
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
              const FaIcon(
                AppIcons.trendUp,
                color: Color(0xFFFF6B00),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text('MILEAGE TREND', style: AppFonts.sectionHeader()),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Factory: ${AppConstants.factoryMileage.toStringAsFixed(0)} km/l',
                  style: AppFonts.caption(
                    color: const Color(0xFFFF6B00),
                    size: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: AppConstants.factoryMileage,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: v == AppConstants.factoryMileage
                        ? const Color(0xFFFF6B00).withValues(alpha: 0.35)
                        : Colors.white10,
                    strokeWidth: v == AppConstants.factoryMileage ? 1.5 : 0.5,
                    dashArray: v == AppConstants.factoryMileage ? [4, 4] : null,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(0),
                        style: AppFonts.caption(size: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final d = data[i].date;
                        return Text(
                          '${d.day}/${d.month}',
                          style: AppFonts.caption(size: 8),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFFFF6B00),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: spot.y >= AppConstants.factoryMileage
                                ? Colors.greenAccent
                                : const Color(0xFFFF6B00),
                            strokeWidth: 1.5,
                            strokeColor: Colors.black,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFF6B00).withValues(alpha: 0.25),
                          const Color(0xFFFF6B00).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF1A1A1A),
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} km/l',
                            TextStyle(
                              color: s.y >= AppConstants.factoryMileage
                                  ? Colors.greenAccent
                                  : const Color(0xFFFF6B00),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
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

// ── Input Form ─────────────────────────────────────────────────────────────────

class _InputForm extends StatelessWidget {
  const _InputForm({
    required this.formKey,
    required this.litresCtrl,
    required this.kmCtrl,
    required this.priceCtrl,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController litresCtrl;
  final TextEditingController kmCtrl;
  final TextEditingController priceCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.2),
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'mileage.log_fillup'.tr().toUpperCase(),
              style: AppFonts.sectionHeader(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: litresCtrl,
                    label: 'mileage.litres_filled'.tr(),
                    suffix: 'L',
                    hint: '3.5',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: kmCtrl,
                    label: 'mileage.km_driven'.tr(),
                    suffix: 'km',
                    hint: '120',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Field(
              controller: priceCtrl,
              label: 'mileage.price_per_litre'.tr(),
              suffix: '₹/L',
              hint: '106',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const FaIcon(AppIcons.add, size: 16),
                label: Text(
                  'mileage.calculate'.tr(),
                  style: AppFonts.button(size: 14),
                ),
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppFonts.body(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.caption(size: 12),
        hintText: hint,
        hintStyle: AppFonts.caption(color: Colors.white24),
        suffixText: suffix,
        suffixStyle: AppFonts.body(
          color: const Color(0xFFFF6B00),
          weight: FontWeight.bold,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (double.tryParse(v) == null) return 'Invalid';
        if (double.parse(v) <= 0) return '> 0';
        return null;
      },
    );
  }
}

// ── Entry Tile ─────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});
  final FuelEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mileageColor = entry.actualMileage >= AppConstants.factoryMileage
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: mileageColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mileageColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.actualMileage.toStringAsFixed(1),
                  style: AppFonts.hud(
                    size: 16,
                    color: mileageColor,
                    height: 1.2,
                  ),
                ),
                Text('km/l', style: AppFonts.caption(size: 9)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.litresFilled.toStringAsFixed(2)} L  •  ${entry.kmDriven.toStringAsFixed(0)} km',
                  style: AppFonts.body(weight: FontWeight.w600, size: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${entry.totalCost.toStringAsFixed(0)} spent  •  ₹${entry.costPerKm.toStringAsFixed(2)}/km',
                  style: AppFonts.body(color: Colors.white54, size: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}',
                  style: AppFonts.caption(size: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const FaIcon(
              AppIcons.delete,
              color: Colors.white24,
              size: 16,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
