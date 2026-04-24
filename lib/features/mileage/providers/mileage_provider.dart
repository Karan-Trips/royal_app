import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:royal_app/core/models/fuel_entry.dart';
import 'package:royal_app/core/services/hive_service.dart';

part 'mileage_provider.g.dart';

class MileageStats {
  const MileageStats({
    required this.entries,
    required this.avgMileage,
    required this.totalLitres,
    required this.totalCost,
    required this.totalKm,
  });

  final List<FuelEntry> entries;
  final double avgMileage;   // km/l average across all entries
  final double totalLitres;  // total litres filled
  final double totalCost;    // total ₹ spent on fuel
  final double totalKm;      // total km tracked via fill-ups

  bool get hasEntries => entries.isNotEmpty;
}

@riverpod
class MileageNotifier extends _$MileageNotifier {
  @override
  MileageStats build() => _compute(HiveService.instance.fuelEntries);

  Future<void> addEntry({
    required double litresFilled,
    required double kmDriven,
    required double pricePerLitre,
  }) async {
    final entry = FuelEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      litresFilled: litresFilled,
      kmDriven: kmDriven,
      pricePerLitre: pricePerLitre,
    );
    await HiveService.instance.saveFuelEntry(entry);
    state = _compute(HiveService.instance.fuelEntries);
  }

  Future<void> deleteEntry(String id) async {
    await HiveService.instance.deleteFuelEntry(id);
    state = _compute(HiveService.instance.fuelEntries);
  }

  MileageStats _compute(List<FuelEntry> entries) {
    if (entries.isEmpty) {
      return const MileageStats(
        entries: [],
        avgMileage: 0,
        totalLitres: 0,
        totalCost: 0,
        totalKm: 0,
      );
    }
    final totalLitres =
        entries.fold(0.0, (sum, e) => sum + e.litresFilled);
    final totalKm = entries.fold(0.0, (sum, e) => sum + e.kmDriven);
    final totalCost = entries.fold(0.0, (sum, e) => sum + e.totalCost);
    final avgMileage = totalLitres > 0 ? totalKm / totalLitres : 0.0;

    return MileageStats(
      entries: entries,
      avgMileage: avgMileage,
      totalLitres: totalLitres,
      totalCost: totalCost,
      totalKm: totalKm,
    );
  }
}
