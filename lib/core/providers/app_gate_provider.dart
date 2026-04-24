import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:royal_app/core/services/biometric_service.dart';

part 'app_gate_provider.g.dart';

// ── Gate status ────────────────────────────────────────────────────────────────

enum GateStatus {
  idle,            // initial — nothing attempted yet
  authenticating,  // biometric prompt is open
  authFailed,      // biometric denied / not available
  locating,        // fetching GPS
  locationDenied,  // GPS permission denied or service off
  ready,           // both passed → show dashboard
}

// ── Gate state ─────────────────────────────────────────────────────────────────

class AppGateState {
  const AppGateState({
    this.status = GateStatus.idle,
    this.position,
    this.errorMessage,
    this.biometricLabel,
  });

  final GateStatus status;
  final Position?  position;        // GPS position once granted
  final String?    errorMessage;
  final String?    biometricLabel;  // e.g. "Face ID", "Fingerprint"

  bool get isLoading =>
      status == GateStatus.authenticating || status == GateStatus.locating;

  AppGateState copyWith({
    GateStatus? status,
    Position?   position,
    String?     errorMessage,
    String?     biometricLabel,
  }) =>
      AppGateState(
        status:         status         ?? this.status,
        position:       position       ?? this.position,
        errorMessage:   errorMessage   ?? this.errorMessage,
        biometricLabel: biometricLabel ?? this.biometricLabel,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

@riverpod
class AppGateNotifier extends _$AppGateNotifier {
  final _biometric = BiometricService.instance;

  @override
  AppGateState build() => const AppGateState();

  /// Full gate sequence: biometric → GPS.
  /// Safe to call multiple times (retry button).
  Future<void> authenticate() async {
    // Pre-fetch biometric label for UI display
    final label = await _biometric.biometricLabel;

    state = state.copyWith(
      status: GateStatus.authenticating,
      errorMessage: null,
      biometricLabel: label,
    );

    // ── Step 1: Biometric ──────────────────────────────────────────────────
    final result = await _biometric.authenticate(
      reason: 'Authenticate to access MotoStack',
    );

    switch (result) {
      case BiometricSuccess():
        break; // continue to GPS

      case BiometricNotAvailable(:final reason):
        state = state.copyWith(
          status: GateStatus.authFailed,
          errorMessage: reason,
        );
        return;

      case BiometricFailure(:final reason):
        state = state.copyWith(
          status: GateStatus.authFailed,
          errorMessage: reason,
        );
        return;

      case BiometricError(:final message):
        state = state.copyWith(
          status: GateStatus.authFailed,
          errorMessage: message,
        );
        return;
    }

    // ── Step 2: Location ───────────────────────────────────────────────────
    state = state.copyWith(status: GateStatus.locating);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: GateStatus.locationDenied,
          errorMessage: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: GateStatus.locationDenied,
          errorMessage: permission == LocationPermission.deniedForever
              ? 'Location permission permanently denied. Enable it in Settings.'
              : 'Location permission denied. MotoStack needs GPS to track rides.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      state = state.copyWith(status: GateStatus.ready, position: position);
    } catch (e) {
      state = state.copyWith(
        status: GateStatus.locationDenied,
        errorMessage: 'Could not get location: $e',
      );
    }
  }

  /// Cancel any in-progress biometric prompt.
  Future<void> cancel() => _biometric.cancel();
}
