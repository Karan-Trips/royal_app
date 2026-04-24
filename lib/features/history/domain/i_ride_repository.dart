import 'package:latlong2/latlong.dart';
import 'package:royal_app/features/history/domain/ride_entity.dart';

abstract interface class IRideRepository {
  Future<void> saveRide({
    required List<LatLng> points,
    required double distanceKm,
    required double cost,
    required int    durationSeconds,
    required double maxSpeedKmh,
    required double avgSpeedKmh,
  });

  Future<List<RideEntity>> fetchRides();
}
