import 'package:hive_flutter/hive_flutter.dart';
import 'package:royal_app/core/models/fuel_entry.dart';

// ── Box names ─────────────────────────────────────────────────────────────────
const _kStatsBox      = 'ride_stats';
const _kStatsMetaBox  = 'ride_stats_meta';
const _kPointsBox     = 'ride_points';
const _kFuelLogBox    = 'fuel_log';
const _kHistoryBox    = 'daily_history'; // key=YYYY-MM-DD, value=km (double)

// ── Stat keys ─────────────────────────────────────────────────────────────────
const _kTotalDistance = 'total_distance';
const _kTodayDistance = 'today_distance';
const _kFuelWallet    = 'fuel_wallet';
const _kLastSavedDate = 'last_saved_date';

class HiveService {
  HiveService._();
  static final instance = HiveService._();

  late Box<double>  _statsBox;
  late Box<String>  _statsMetaBox;
  late Box<List>    _pointsBox;
  late Box<Map>     _fuelLogBox;
  late Box<double>  _historyBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _statsBox     = await Hive.openBox<double>(_kStatsBox);
    _statsMetaBox = await Hive.openBox<String>(_kStatsMetaBox);
    _pointsBox    = await Hive.openBox<List>(_kPointsBox);
    _fuelLogBox   = await Hive.openBox<Map>(_kFuelLogBox);
    _historyBox   = await Hive.openBox<double>(_kHistoryBox);
  }

  // ── Ride Stats ────────────────────────────────────────────────────────────

  double get totalDistance =>
      _statsBox.get(_kTotalDistance, defaultValue: 0.0)!;

  double get todayDistance {
    final saved = _statsMetaBox.get(_kLastSavedDate, defaultValue: '');
    if (saved != _todayKey()) return 0.0;
    return _statsBox.get(_kTodayDistance, defaultValue: 0.0)!;
  }

  double get fuelWallet =>
      _statsBox.get(_kFuelWallet, defaultValue: 500.0)!;

  Future<void> saveStats({
    required double totalDistance,
    required double todayDistance,
    required double fuelWallet,
  }) async {
    await _statsBox.put(_kTotalDistance, totalDistance);
    await _statsBox.put(_kTodayDistance, todayDistance);
    await _statsBox.put(_kFuelWallet, fuelWallet);
    await _statsMetaBox.put(_kLastSavedDate, _todayKey());
    // Also update today's history bucket
    await _historyBox.put(_todayKey(), todayDistance);
  }

  // ── Daily History (for chart) ─────────────────────────────────────────────

  /// Returns last [days] days as {dateKey: km} sorted oldest→newest.
  Map<String, double> getDailyHistory({int days = 7}) {
    final result = <String, double>{};
    final now = DateTime.now();
    for (var i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = _dateKey(d);
      result[key] = _historyBox.get(key, defaultValue: 0.0)!;
    }
    return result;
  }

  // ── Ride Points ───────────────────────────────────────────────────────────

  List<double> get savedPoints {
    final raw = _pointsBox.get('points', defaultValue: <dynamic>[]);
    return raw?.cast<double>() ?? [];
  }

  Future<void> savePoints(List<double> flat) =>
      _pointsBox.put('points', flat);

  Future<void> clearPoints() =>
      _pointsBox.put('points', <double>[]);

  // ── Fuel Log ──────────────────────────────────────────────────────────────

  List<FuelEntry> get fuelEntries {
    return _fuelLogBox.values
        .map((m) => FuelEntry.fromMap(m))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveFuelEntry(FuelEntry entry) =>
      _fuelLogBox.put(entry.id, entry.toMap());

  Future<void> deleteFuelEntry(String id) =>
      _fuelLogBox.delete(id);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _todayKey() => _dateKey(DateTime.now());

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
