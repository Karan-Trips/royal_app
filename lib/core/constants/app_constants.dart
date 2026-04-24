/// All Royal Enfield Meteor 350 Supernova constants in one place.
class AppConstants {
  AppConstants._();

  // ── Bike ──────────────────────────────────────────────────────────────────
  static const String bikeName = 'Royal Enfield Meteor 350';
  static const String bikeVariant = 'Supernova Red';

  // ── Fuel Economics ────────────────────────────────────────────────────────
  /// Petrol price per litre in Ahmedabad (₹)
  static const double petrolPricePerLitre = 106.0;

  /// Factory claimed mileage (km/l)
  static const double factoryMileage = 35.0;

  /// Derived cost per km (₹)
  static const double costPerKm = petrolPricePerLitre / factoryMileage; // 3.03

  /// Litres consumed per km
  static const double litresPerKm = 1.0 / factoryMileage;

  // ── Ride Goals ────────────────────────────────────────────────────────────
  /// Fixed daily Ahmedabad commute loop (km)
  static const double dailyTargetKm = 12.0;

  /// Starting fuel wallet balance (₹)
  static const double initialWalletBalance = 500.0;

  // ── Location ──────────────────────────────────────────────────────────────
  static const double ahmedabadLat = 23.0225;
  static const double ahmedabadLng = 72.5714;
  static const double heatWarningThreshold = 40.0;
}
