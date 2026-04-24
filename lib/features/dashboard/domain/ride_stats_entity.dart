import 'package:royal_app/core/constants/app_constants.dart';

class RideStatsEntity {
  const RideStatsEntity({
    this.totalDistance = 0.0,
    this.todayDistance = 0.0,
    this.fuelWallet = AppConstants.initialWalletBalance,
  });

  final double totalDistance;
  final double todayDistance;
  final double fuelWallet;

  double get dailyProgress =>
      (todayDistance / AppConstants.dailyTargetKm).clamp(0.0, 1.0);
  bool   get dailyGoalMet    => todayDistance >= AppConstants.dailyTargetKm;
  double get fuelUsedLitres  => todayDistance * AppConstants.litresPerKm;
  double get fuelUsedCost    => todayDistance * AppConstants.costPerKm;

  RideStatsEntity copyWith({
    double? totalDistance,
    double? todayDistance,
    double? fuelWallet,
  }) => RideStatsEntity(
    totalDistance: totalDistance ?? this.totalDistance,
    todayDistance: todayDistance ?? this.todayDistance,
    fuelWallet:    fuelWallet    ?? this.fuelWallet,
  );

  RideStatsEntity addDistance(double km) => copyWith(
    totalDistance: totalDistance + km,
    todayDistance: todayDistance + km,
    fuelWallet:    fuelWallet - (km * AppConstants.costPerKm),
  );
}
