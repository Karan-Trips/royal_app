import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:royal_app/core/constants/app_constants.dart';
import 'package:royal_app/core/constants/app_fonts_icons.dart';
import 'package:royal_app/core/providers/locale_provider.dart';
import 'package:royal_app/core/theme/theme_provider.dart';
import 'package:royal_app/features/dashboard/providers/moto_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark        = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final currentLocale = ref.watch(localeNotifierProvider);
    final stats         = ref.watch(rideStatsNotifierProvider);
    final cs            = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [

          // ── Language ──────────────────────────────────────────────────
          _SectionHeader(label: 'settings.language'.tr()),
          _LanguageTile(
            label: 'settings.english'.tr(),
            locale: const Locale('en'),
            selected: currentLocale.languageCode == 'en',
            onTap: () => ref
                .read(localeNotifierProvider.notifier)
                .setLocale(context, const Locale('en')),
          ),
          _LanguageTile(
            label: 'settings.hindi'.tr(),
            locale: const Locale('hi'),
            selected: currentLocale.languageCode == 'hi',
            onTap: () => ref
                .read(localeNotifierProvider.notifier)
                .setLocale(context, const Locale('hi')),
          ),

          const SizedBox(height: 8),

          // ── Theme ─────────────────────────────────────────────────────
          _SectionHeader(label: 'settings.theme'.tr()),
          SwitchListTile(
            secondary: FaIcon(
              isDark ? AppIcons.darkMode : AppIcons.lightMode,
              color: const Color(0xFFFF6B00),
              size: 18,
            ),
            title: Text(
              isDark
                  ? 'settings.dark_mode'.tr()
                  : 'settings.light_mode'.tr(),
              style: AppFonts.body(size: 14, weight: FontWeight.w500),
            ),
            value: isDark,
            activeThumbColor: const Color(0xFFFF6B00),
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(themeNotifierProvider.notifier).toggle();
            },
          ),

          const SizedBox(height: 8),

          // ── Fuel Wallet ───────────────────────────────────────────────
          _SectionHeader(label: 'settings.fuel_wallet'.tr()),
          ListTile(
            leading: const FaIcon(AppIcons.wallet, color: Color(0xFFFFD740), size: 18),
            title: Text('settings.wallet_balance'.tr(), style: AppFonts.body(size: 14)),
            trailing: Text(
              '₹${stats.fuelWallet.toStringAsFixed(0)}',
              style: AppFonts.body(
                size: 14,
                weight: FontWeight.bold,
                color: const Color(0xFFFFD740),
              ),
            ),
          ),
          ListTile(
            leading: const FaIcon(AppIcons.fuel, color: Color(0xFF69F0AE), size: 18),
            title: Text('settings.topup_fuel'.tr(), style: AppFonts.body(size: 14)),
            trailing: const FaIcon(AppIcons.add, color: Color(0xFFFF6B00), size: 14),
            onTap: () => _showTopUpDialog(context, ref),
          ),
          ListTile(
            leading: const FaIcon(AppIcons.timer, color: Color(0xFF4FC3F7), size: 18),
            title: Text('settings.reset_day'.tr(), style: AppFonts.body(size: 14)),
            subtitle: Text(
              'settings.reset_day_sub'.tr(),
              style: AppFonts.caption(size: 11, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            trailing: const FaIcon(AppIcons.close, color: Colors.redAccent, size: 14),
            onTap: () => _confirmResetDay(context, ref),
          ),

          const SizedBox(height: 8),

          // ── Ride Stats ────────────────────────────────────────────────
          _SectionHeader(label: 'settings.ride_stats'.tr()),
          _StatRow(
            icon: AppIcons.route,
            color: const Color(0xFF4FC3F7),
            label: 'settings.total_distance'.tr(),
            value: '${stats.totalDistance.toStringAsFixed(1)} km',
          ),
          _StatRow(
            icon: AppIcons.costPerKm,
            color: const Color(0xFFFF6B00),
            label: 'settings.cost_per_km'.tr(),
            value: '₹${AppConstants.costPerKm.toStringAsFixed(2)}/km',
          ),
          _StatRow(
            icon: AppIcons.thermometer,
            color: const Color(0xFFFF6B00),
            label: 'settings.daily_goal'.tr(),
            value: '${AppConstants.dailyTargetKm.toStringAsFixed(0)} km',
          ),

          const SizedBox(height: 8),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader(label: 'settings.about'.tr()),
          ListTile(
            leading: const FaIcon(AppIcons.motorcycle, color: Color(0xFFFF6B00), size: 18),
            title: Text('settings.bike_name'.tr(), style: AppFonts.body(size: 14)),
            trailing: Text(
              AppConstants.bikeVariant,
              style: AppFonts.caption(size: 11, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          ListTile(
            leading: const FaIcon(AppIcons.info, color: Color(0xFFFF6B00), size: 18),
            title: Text('settings.app_version'.tr(), style: AppFonts.body(size: 14)),
            trailing: Text(
              'settings.version_value'.tr(),
              style: AppFonts.caption(size: 11, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
          ListTile(
            leading: const FaIcon(AppIcons.language, color: Color(0xFFFF6B00), size: 18),
            title: Text('settings.location'.tr(), style: AppFonts.body(size: 14)),
            trailing: Text(
              'Ahmedabad, GJ',
              style: AppFonts.caption(size: 11, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings.topup_title'.tr()),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: 'settings.topup_hint'.tr(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('settings.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                ref.read(rideStatsNotifierProvider.notifier).topUpFuel(amount);
                HapticFeedback.lightImpact();
              }
              Navigator.pop(ctx);
            },
            child: Text('settings.add'.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmResetDay(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('settings.reset_confirm_title'.tr()),
        content: Text('settings.reset_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('settings.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(rideStatsNotifierProvider.notifier).resetDay();
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
            },
            child: Text('settings.reset'.tr()),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(label.toUpperCase(), style: AppFonts.sectionHeader()),
    );
  }
}

// ── Language Tile ──────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final String       label;
  final Locale       locale;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor:
            selected ? const Color(0xFFFF6B00) : Colors.transparent,
        child: Text(
          locale.languageCode.toUpperCase(),
          style: AppFonts.caption(
            size: 10,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(label, style: AppFonts.body(size: 14)),
      trailing: selected
          ? const FaIcon(AppIcons.check, color: Color(0xFFFF6B00), size: 16)
          : null,
      onTap: onTap,
    );
  }
}

// ── Stat Row ───────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final FaIconData icon;
  final Color      color;
  final String     label;
  final String     value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FaIcon(icon, color: color, size: 18),
      title: Text(label, style: AppFonts.body(size: 14)),
      trailing: Text(
        value,
        style: AppFonts.body(size: 13, weight: FontWeight.bold, color: color),
      ),
    );
  }
}
