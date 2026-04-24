import 'package:latlong2/latlong.dart';

class TrackingEntity {
  const TrackingEntity({
    this.points = const [],
    this.currentPosition,
    this.isTracking = false,
    this.isLocating = false,
    this.currentSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.elapsedSeconds = 0,
    this.heading = 0.0,
    this.accuracy = 0.0,
    this.isBackground = false,
  });

  final List<LatLng> points;
  final LatLng?      currentPosition;
  final bool         isTracking;
  final bool         isLocating;
  final double       currentSpeedKmh;
  final double       maxSpeedKmh;
  final int          elapsedSeconds;
  final double       heading;
  final double       accuracy;
  final bool         isBackground;

  double get distanceKm {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += const Distance().as(LengthUnit.Kilometer, points[i - 1], points[i]);
    }
    return total;
  }

  double get avgSpeedKmh {
    if (elapsedSeconds == 0 || distanceKm == 0) return 0.0;
    return distanceKm / (elapsedSeconds / 3600.0);
  }

  String get elapsedFormatted {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TrackingEntity copyWith({
    List<LatLng>? points,
    LatLng?       currentPosition,
    bool?         isTracking,
    bool?         isLocating,
    double?       currentSpeedKmh,
    double?       maxSpeedKmh,
    int?          elapsedSeconds,
    double?       heading,
    double?       accuracy,
    bool?         isBackground,
  }) => TrackingEntity(
    points:          points          ?? this.points,
    currentPosition: currentPosition ?? this.currentPosition,
    isTracking:      isTracking      ?? this.isTracking,
    isLocating:      isLocating      ?? this.isLocating,
    currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
    maxSpeedKmh:     maxSpeedKmh     ?? this.maxSpeedKmh,
    elapsedSeconds:  elapsedSeconds  ?? this.elapsedSeconds,
    heading:         heading         ?? this.heading,
    accuracy:        accuracy        ?? this.accuracy,
    isBackground:    isBackground    ?? this.isBackground,
  );
}
