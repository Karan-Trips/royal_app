import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';

class RideEntity {
  const RideEntity({
    required this.id,
    required this.encodedPolyline,
    required this.distanceKm,
    required this.cost,
    required this.timestamp,
    required this.durationSeconds,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.pointCount,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  final String   id;
  final String   encodedPolyline;
  final double   distanceKm;
  final double   cost;
  final DateTime timestamp;
  final int      durationSeconds;
  final double   maxSpeedKmh;
  final double   avgSpeedKmh;
  final int      pointCount;
  final double   startLat;
  final double   startLng;
  final double   endLat;
  final double   endLng;

  LatLng get startPoint => LatLng(startLat, startLng);
  LatLng get endPoint   => LatLng(endLat, endLng);

  List<LatLng> get decodedPoints => decodePolyline(encodedPolyline)
      .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
      .toList();

  String get durationFormatted {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }
}
