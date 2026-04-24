import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:royal_app/core/providers/app_gate_provider.dart';
import 'package:royal_app/core/services/background_location_service.dart';
import 'package:royal_app/core/services/hive_service.dart';
import 'package:royal_app/features/dashboard/presentation/providers/moto_provider.dart';
import 'package:royal_app/features/tracking/domain/tracking_entity.dart';

part 'tracking_provider.g.dart';

// Re-export entity as TrackingState for backward compat
typedef TrackingState = TrackingEntity;

// ── Notifier ───────────────────────────────────────────────────────────────────

@riverpod
class TrackingNotifier extends _$TrackingNotifier {
  // Foreground GPS stream subscription (Geolocator)
  StreamSubscription<Position>?         _fgSub;
  // Background location stream subscription (IsolateNameServer bridge)
  StreamSubscription<BgLocationUpdate>? _bgSub;
  // Elapsed-time ticker
  Timer?                                _timer;

  static const _fallbackCenter = LatLng(23.0225, 72.5714);
  final _bgService = BackgroundLocationService.instance;

  @override
  TrackingState build() {
    ref.onDispose(_cleanup);

    final gatePos = ref.read(appGateNotifierProvider).position;
    final initial = gatePos != null
        ? LatLng(gatePos.latitude, gatePos.longitude)
        : _fallbackCenter;

    // Restore persisted polyline
    final savedFlat      = HiveService.instance.savedPoints;
    final restoredPoints = <LatLng>[];
    for (var i = 0; i + 1 < savedFlat.length; i += 2) {
      restoredPoints.add(LatLng(savedFlat[i], savedFlat[i + 1]));
    }

    Future.microtask(fetchCurrentLocation);

    return TrackingState(
      currentPosition: initial,
      points:          restoredPoints,
      isLocating:      initial == _fallbackCenter,
    );
  }

  // ── One-shot location ──────────────────────────────────────────────────────

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLocating: true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      state = state.copyWith(
        currentPosition: LatLng(pos.latitude, pos.longitude),
        isLocating: false,
      );
    } catch (_) {
      state = state.copyWith(isLocating: false);
    }
  }

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> startTracking() async {
    // Ensure foreground permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) { return; }

    await HiveService.instance.clearPoints();
    state = state.copyWith(
      isTracking:      true,
      points:          [],
      elapsedSeconds:  0,
      currentSpeedKmh: 0,
      maxSpeedKmh:     0,
      isBackground:    false,
    );

    // ── Elapsed timer (foreground only) ──────────────────────────────────────
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isBackground) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });

    // ── Foreground GPS stream (Geolocator) ────────────────────────────────────
    // High-frequency, accurate updates while app is visible.
    _fgSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:       LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      // While foreground, push directly — skip background isolate overhead.
      if (!state.isBackground) {
        _handleUpdate(
          lat:      pos.latitude,
          lng:      pos.longitude,
          speedMs:  pos.speed,
          heading:  pos.heading,
          accuracy: pos.accuracy,
        );
      }
    });

    // ── Background location stream (IsolateNameServer bridge) ─────────────────
    // Updates arrive here when the app is backgrounded / killed.
    await _bgService.startTracking();
    _bgSub = _bgService.locationStream.listen((update) {
      // Only process background updates when actually in background.
      // Foreground updates come from Geolocator above.
      if (state.isBackground) {
        _handleUpdate(
          lat:     update.lat,
          lng:     update.lng,
          speedMs: update.speedMs,
          heading: update.headingDeg,
        );
      }
    });
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  Future<void> stopTracking() async {
    await _bgService.stopTracking();
    _cleanup();
    state = state.copyWith(
      isTracking:      false,
      currentSpeedKmh: 0,
      isBackground:    false,
    );
  }

  // ── Lifecycle hooks (called from TrackingScreen via AppLifecycleListener) ──

  void onAppBackground() {
    if (state.isTracking) state = state.copyWith(isBackground: true);
  }

  void onAppForeground() {
    state = state.copyWith(isBackground: false);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _handleUpdate({
    required double lat,
    required double lng,
    required double speedMs,
    required double heading,
    double accuracy = 0.0,
  }) {
    final point     = LatLng(lat, lng);
    final newPoints = [...state.points, point];
    final speedKmh  = speedMs < 0 ? 0.0 : (speedMs * 3.6).clamp(0.0, 300.0);
    final maxSpeed  =
        speedKmh > state.maxSpeedKmh ? speedKmh : state.maxSpeedKmh;

    // Accumulate distance
    if (newPoints.length >= 2) {
      final prev = newPoints[newPoints.length - 2];
      final dist =
          const Distance().as(LengthUnit.Kilometer, prev, point);
      ref.read(rideStatsNotifierProvider.notifier).addDistance(dist);
    }

    // Persist to Hive (survives app kill)
    final flat = <double>[];
    for (final p in newPoints) {
      flat
        ..add(p.latitude)
        ..add(p.longitude);
    }
    HiveService.instance.savePoints(flat);

    state = state.copyWith(
      points:          newPoints,
      currentPosition: point,
      currentSpeedKmh: speedKmh,
      maxSpeedKmh:     maxSpeed,
      heading:         heading < 0 ? 0 : heading % 360,
      accuracy:        accuracy.clamp(0.0, 500.0),
    );
  }

  void _cleanup() {
    _fgSub?.cancel();
    _fgSub = null;
    _bgSub?.cancel();
    _bgSub = null;
    _timer?.cancel();
    _timer = null;
  }
}
