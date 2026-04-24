import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';
import 'package:royal_app/features/history/domain/i_ride_repository.dart';
import 'package:royal_app/features/history/domain/ride_entity.dart';

// ── Firestore mapper ──────────────────────────────────────────────────────────

extension _RideEntityX on RideEntity {
  Map<String, dynamic> toFirestore() => {
    'polyline':    encodedPolyline,
    'distanceKm':  distanceKm,
    'cost':        cost,
    'timestamp':   FieldValue.serverTimestamp(),
    'durationSec': durationSeconds,
    'maxSpeedKmh': maxSpeedKmh,
    'avgSpeedKmh': avgSpeedKmh,
    'pointCount':  pointCount,
    'startLat':    startLat,
    'startLng':    startLng,
    'endLat':      endLat,
    'endLng':      endLng,
    'startGeo':    GeoPoint(startLat, startLng),
    'endGeo':      GeoPoint(endLat, endLng),
  };
}

RideEntity _fromDoc(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>;
  return RideEntity(
    id:              doc.id,
    encodedPolyline: d['polyline']     as String,
    distanceKm:      (d['distanceKm']  as num).toDouble(),
    cost:            (d['cost']        as num).toDouble(),
    timestamp:       (d['timestamp']   as Timestamp).toDate(),
    durationSeconds: (d['durationSec'] as num? ?? 0).toInt(),
    maxSpeedKmh:     (d['maxSpeedKmh'] as num? ?? 0).toDouble(),
    avgSpeedKmh:     (d['avgSpeedKmh'] as num? ?? 0).toDouble(),
    pointCount:      (d['pointCount']  as num? ?? 0).toInt(),
    startLat:        (d['startLat']    as num? ?? 0).toDouble(),
    startLng:        (d['startLng']    as num? ?? 0).toDouble(),
    endLat:          (d['endLat']      as num? ?? 0).toDouble(),
    endLng:          (d['endLng']      as num? ?? 0).toDouble(),
  );
}

// ── Polyline decode helper ────────────────────────────────────────────────────

List<LatLng> decodeRidePolyline(String encoded) =>
    decodePolyline(encoded)
        .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
        .toList();

// ── Implementation ────────────────────────────────────────────────────────────

class RideRepository implements IRideRepository {
  RideRepository._();
  static final instance = RideRepository._();

  final _col = FirebaseFirestore.instance.collection('rides');

  @override
  Future<void> saveRide({
    required List<LatLng> points,
    required double distanceKm,
    required double cost,
    required int    durationSeconds,
    required double maxSpeedKmh,
    required double avgSpeedKmh,
  }) async {
    if (points.length < 2) return;

    final encoded = encodePolyline(
      points.map((p) => [p.latitude, p.longitude]).toList(),
    );

    final entity = RideEntity(
      id:              '',
      encodedPolyline: encoded,
      distanceKm:      distanceKm,
      cost:            cost,
      timestamp:       DateTime.now(),
      durationSeconds: durationSeconds,
      maxSpeedKmh:     maxSpeedKmh,
      avgSpeedKmh:     avgSpeedKmh,
      pointCount:      points.length,
      startLat:        points.first.latitude,
      startLng:        points.first.longitude,
      endLat:          points.last.latitude,
      endLng:          points.last.longitude,
    );

    await _col.add(entity.toFirestore());
  }

  @override
  Future<List<RideEntity>> fetchRides() async {
    final snap = await _col
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }
}
