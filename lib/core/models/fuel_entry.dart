/// Represents a single fuel fill-up entry logged by the user.
class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.date,
    required this.litresFilled,
    required this.kmDriven,
    required this.pricePerLitre,
  });

  final String id;           // unique key for Hive
  final DateTime date;
  final double litresFilled; // how many litres the user put in
  final double kmDriven;     // km ridden since last fill-up
  final double pricePerLitre;

  /// Actual mileage calculated from this fill-up (km/l)
  double get actualMileage =>
      litresFilled > 0 ? kmDriven / litresFilled : 0.0;

  /// Total cost of this fill-up (₹)
  double get totalCost => litresFilled * pricePerLitre;

  /// Cost per km for this fill-up (₹/km)
  double get costPerKm =>
      kmDriven > 0 ? totalCost / kmDriven : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'litresFilled': litresFilled,
        'kmDriven': kmDriven,
        'pricePerLitre': pricePerLitre,
      };

  factory FuelEntry.fromMap(Map<dynamic, dynamic> map) => FuelEntry(
        id: map['id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        litresFilled: (map['litresFilled'] as num).toDouble(),
        kmDriven: (map['kmDriven'] as num).toDouble(),
        pricePerLitre: (map['pricePerLitre'] as num).toDouble(),
      );
}
