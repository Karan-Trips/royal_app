import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:royal_app/core/constants/app_constants.dart';
import 'package:royal_app/core/services/hive_service.dart';
import 'package:royal_app/core/utils/weather_helper.dart';

part 'moto_provider.g.dart';

// ── Ride Stats Model ──────────────────────────────────────────────────────────

class RideStats {
  const RideStats({
    this.totalDistance = 0.0,
    this.todayDistance = 0.0,
    this.fuelWallet = AppConstants.initialWalletBalance,
  });

  final double totalDistance;
  final double todayDistance;
  final double fuelWallet;

  double get dailyProgress =>
      (todayDistance / AppConstants.dailyTargetKm).clamp(0.0, 1.0);
  bool get dailyGoalMet => todayDistance >= AppConstants.dailyTargetKm;
  double get fuelUsedLitres => todayDistance * AppConstants.litresPerKm;
  double get fuelUsedCost => todayDistance * AppConstants.costPerKm;

  RideStats copyWith({
    double? totalDistance,
    double? todayDistance,
    double? fuelWallet,
  }) =>
      RideStats(
        totalDistance: totalDistance ?? this.totalDistance,
        todayDistance: todayDistance ?? this.todayDistance,
        fuelWallet: fuelWallet ?? this.fuelWallet,
      );

  RideStats addDistance(double km) => copyWith(
        totalDistance: totalDistance + km,
        todayDistance: todayDistance + km,
        fuelWallet: fuelWallet - (km * AppConstants.costPerKm),
      );
}

// ── Ride Stats Notifier ───────────────────────────────────────────────────────

@riverpod
class RideStatsNotifier extends _$RideStatsNotifier {
  @override
  RideStats build() {
    final hive = HiveService.instance;
    return RideStats(
      totalDistance: hive.totalDistance,
      todayDistance: hive.todayDistance,
      fuelWallet: hive.fuelWallet,
    );
  }

  void addDistance(double km) => _update(state.addDistance(km));
  void resetDay() => _update(state.copyWith(todayDistance: 0.0));
  void topUpFuel(double amount) =>
      _update(state.copyWith(fuelWallet: state.fuelWallet + amount));

  void _update(RideStats next) {
    state = next;
    HiveService.instance.saveStats(
      totalDistance: next.totalDistance,
      todayDistance: next.todayDistance,
      fuelWallet: next.fuelWallet,
    );
  }
}

// ── Ignition State ────────────────────────────────────────────────────────────

@riverpod
class IgnitionNotifier extends _$IgnitionNotifier {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

// ── Weather Provider ──────────────────────────────────────────────────────────

@riverpod
Future<double> ahmedabadTemp(Ref ref) => fetchAhmedabadTemp();

// ── Daily History Provider (for chart) ───────────────────────────────────────

@riverpod
Map<String, double> dailyHistory(Ref ref) {
  // Re-read whenever RideStats changes so chart stays live
  ref.watch(rideStatsNotifierProvider);
  return HiveService.instance.getDailyHistory(days: 7);
}
