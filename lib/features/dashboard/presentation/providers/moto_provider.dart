import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:royal_app/core/constants/app_constants.dart';
import 'package:royal_app/core/providers/app_gate_provider.dart';
import 'package:royal_app/core/services/hive_service.dart';
import 'package:royal_app/core/utils/weather_helper.dart';
import 'package:royal_app/features/dashboard/domain/ride_stats_entity.dart';

part 'moto_provider.g.dart';

// ── Re-export entity as RideStats for backward compat ─────────────────────────
typedef RideStats = RideStatsEntity;

// ── Ride Stats Notifier ───────────────────────────────────────────────────────

@riverpod
class RideStatsNotifier extends _$RideStatsNotifier {
  @override
  RideStats build() {
    final hive = HiveService.instance;
    return RideStats(
      totalDistance: hive.totalDistance,
      todayDistance: hive.todayDistance,
      fuelWallet:    hive.fuelWallet,
    );
  }

  void addDistance(double km) => _update(state.addDistance(km));
  void resetDay()              => _update(state.copyWith(todayDistance: 0.0));
  void topUpFuel(double amount) =>
      _update(state.copyWith(fuelWallet: state.fuelWallet + amount));

  void _update(RideStats next) {
    state = next;
    HiveService.instance.saveStats(
      totalDistance: next.totalDistance,
      todayDistance: next.todayDistance,
      fuelWallet:    next.fuelWallet,
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
Future<double> ahmedabadTemp(Ref ref) {
  final position = ref.watch(appGateNotifierProvider).position;
  return fetchAhmedabadTemp(
    latitude:  position?.latitude  ?? AppConstants.ahmedabadLat,
    longitude: position?.longitude ?? AppConstants.ahmedabadLng,
  );
}

// ── Daily History Provider (for chart) ───────────────────────────────────────

@riverpod
Map<String, double> dailyHistory(Ref ref) {
  ref.watch(rideStatsNotifierProvider);
  return HiveService.instance.getDailyHistory(days: 7);
}