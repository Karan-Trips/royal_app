import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:flutter/foundation.dart';

// ── Port name registered in IsolateNameServer ──────────────────────────────────
// The background isolate looks this up to send data to the foreground.
const _kPortName = 'motostack_bg_location_port';

// ── Top-level background callback ─────────────────────────────────────────────
// MUST be top-level (not a closure / instance method) and annotated with
// @pragma('vm:entry-point') so the Dart AOT compiler keeps it in release builds.
//
// The plugin spawns a *separate* Flutter engine on Android and calls this
// function inside that engine's isolate. On iOS it is called as a BGTask.
// We cannot access any Riverpod / Hive state here — only raw Dart + isolate
// primitives are safe.

@pragma('vm:entry-point')
void bgLocationCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated(
    (BackgroundLocationUpdateData data) async {
      // Look up the SendPort that the foreground isolate registered.
      final SendPort? port =
          IsolateNameServer.lookupPortByName(_kPortName);

      if (port != null) {
        // Send a plain List — only primitives cross isolate boundaries.
        port.send([
          data.lat,
          data.lon,
          data.speed,
          data.course,
          data.horizontalAccuracy,
          data.alt,
        ]);
      }
      // If port is null the app is fully killed; data is lost for this update.
      // For persistence across kills, save to SharedPreferences here if needed.
    },
  );
}

// ── Location update value object ───────────────────────────────────────────────

class BgLocationUpdate {
  const BgLocationUpdate({
    required this.lat,
    required this.lng,
    required this.speedMs,
    required this.heading,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
  });

  final double   lat;
  final double   lng;
  final double   speedMs;   // m/s — negative means unavailable
  final double   heading;   // degrees — negative means unavailable
  final double   accuracy;  // metres
  final double   altitude;  // metres
  final DateTime timestamp;

  /// Speed in km/h, clamped to [0, 300].
  double get speedKmh => speedMs < 0 ? 0 : (speedMs * 3.6).clamp(0.0, 300.0);

  /// Heading clamped to [0, 360).
  double get headingDeg => heading < 0 ? 0 : heading % 360;

  /// Parse from the raw List sent across the isolate boundary.
  factory BgLocationUpdate.fromList(List<dynamic> raw) => BgLocationUpdate(
        lat:       (raw[0] as num).toDouble(),
        lng:       (raw[1] as num).toDouble(),
        speedMs:   (raw[2] as num).toDouble(),
        heading:   (raw[3] as num).toDouble(),
        accuracy:  (raw[4] as num).toDouble(),
        altitude:  (raw[5] as num).toDouble(),
        timestamp: DateTime.now(),
      );

  @override
  String toString() =>
      'BgLocationUpdate(lat=$lat, lng=$lng, '
      'speed=${speedKmh.toStringAsFixed(1)} km/h, '
      'heading=${headingDeg.toStringAsFixed(0)}°)';
}

// ── Result types ───────────────────────────────────────────────────────────────

sealed class BgLocationResult {
  const BgLocationResult();
}

final class BgLocationStarted extends BgLocationResult {
  const BgLocationStarted();
}

final class BgLocationStopped extends BgLocationResult {
  const BgLocationStopped();
}

final class BgLocationError extends BgLocationResult {
  const BgLocationError(this.message);
  final String message;
}

// ── Service ────────────────────────────────────────────────────────────────────

class BackgroundLocationService {
  BackgroundLocationService._();

  static final BackgroundLocationService instance =
      BackgroundLocationService._();

  // ── Isolate bridge ─────────────────────────────────────────────────────────
  // The foreground isolate owns a ReceivePort. Its SendPort is registered in
  // IsolateNameServer so the background isolate can find and use it.

  ReceivePort?                    _receivePort;
  final _controller = StreamController<BgLocationUpdate>.broadcast();

  /// Broadcast stream of location updates.
  /// Subscribe in the foreground; updates arrive from both foreground GPS
  /// and the background isolate via IsolateNameServer.
  Stream<BgLocationUpdate> get locationStream => _controller.stream;

  bool _initialised = false;
  bool _tracking    = false;

  bool get isTracking => _tracking;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Call once from `main()` **before** `runApp()`.
  /// Registers the background callback and opens the isolate receive port.
  Future<void> init() async {
    if (_initialised) return;

    // 1. Register the background callback with the plugin.
    await BackgroundLocationTrackerManager.initialize(
      bgLocationCallback,
      config: const BackgroundLocationTrackerConfig(
        loggingEnabled: kDebugMode,
        androidConfig: AndroidConfig(
          channelName: 'MotoStack Ride Tracking',
          notificationBody: 'MotoStack is tracking your ride…',
          notificationIcon: 'notification_icon',
          trackingInterval: Duration(seconds: 5),
          distanceFilterMeters: 10,
          enableCancelTrackingAction: true,
        ),
        iOSConfig: IOSConfig(
          activityType: ActivityType.AUTOMOTIVE,
          distanceFilterMeters: 10,
          restartAfterKill: true,
        ),
      ),
    );

    // 2. Open the foreground ReceivePort and register its SendPort so the
    //    background isolate can find it via IsolateNameServer.
    _openReceivePort();

    _initialised = true;
  }

  // ── Start tracking ─────────────────────────────────────────────────────────

  Future<BgLocationResult> startTracking() async {
    if (_tracking) return const BgLocationStarted();

    // Re-open port in case it was closed (e.g. after stopTracking).
    _openReceivePort();

    try {
      await BackgroundLocationTrackerManager.startTracking();
      _tracking = true;
      return const BgLocationStarted();
    } catch (e) {
      return BgLocationError('Failed to start background tracking: $e');
    }
  }

  // ── Stop tracking ──────────────────────────────────────────────────────────

  Future<BgLocationResult> stopTracking() async {
    if (!_tracking) return const BgLocationStopped();

    try {
      await BackgroundLocationTrackerManager.stopTracking();
      _tracking = false;
      _closeReceivePort();
      return const BgLocationStopped();
    } catch (e) {
      return BgLocationError('Failed to stop background tracking: $e');
    }
  }

  // ── Status ─────────────────────────────────────────────────────────────────

  Future<bool> get isRunning =>
      BackgroundLocationTrackerManager.isTracking();

  // ── Foreground push ────────────────────────────────────────────────────────
  // Called by TrackingNotifier when it receives a Geolocator update while
  // the app is in the foreground — keeps a single unified stream.

  void pushForegroundUpdate(BgLocationUpdate update) {
    if (!_controller.isClosed) _controller.add(update);
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _closeReceivePort();
    _controller.close();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _openReceivePort() {
    // Remove any stale registration first.
    IsolateNameServer.removePortNameMapping(_kPortName);

    _receivePort?.close();
    _receivePort = ReceivePort();

    // Register so the background isolate can look it up.
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _kPortName,
    );

    // Listen and forward to the broadcast stream.
    _receivePort!.listen((dynamic message) {
      if (message is List && message.length >= 6) {
        final update = BgLocationUpdate.fromList(message);
        if (!_controller.isClosed) _controller.add(update);
      }
    });
  }

  void _closeReceivePort() {
    IsolateNameServer.removePortNameMapping(_kPortName);
    _receivePort?.close();
    _receivePort = null;
  }
}
