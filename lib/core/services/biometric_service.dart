import 'package:local_auth/local_auth.dart';

// ── Result type ────────────────────────────────────────────────────────────────

sealed class BiometricResult {
  const BiometricResult();
}

/// Authentication succeeded.
final class BiometricSuccess extends BiometricResult {
  const BiometricSuccess();
}

/// Device has no biometric / PIN capability.
final class BiometricNotAvailable extends BiometricResult {
  const BiometricNotAvailable(this.reason);
  final String reason;
}

/// User cancelled or failed authentication.
final class BiometricFailure extends BiometricResult {
  const BiometricFailure(this.reason);
  final String reason;
}

/// Unexpected exception during authentication.
final class BiometricError extends BiometricResult {
  const BiometricError(this.message);
  final String message;
}

// ── Service ────────────────────────────────────────────────────────────────────

class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  // ── Capability checks ──────────────────────────────────────────────────────

  /// Returns true if the device supports biometric or device-credential auth.
  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (face, fingerprint, iris).
  Future<List<BiometricType>> get enrolledBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Returns a human-readable label for the strongest available biometric.
  Future<String> get biometricLabel async {
    final types = await enrolledBiometrics;
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Device PIN';
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Runs the full authentication flow and returns a typed [BiometricResult].
  ///
  /// [reason] is shown in the system prompt.
  /// [allowPinFallback] lets the user fall back to PIN/pattern if biometrics fail.
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to access MotoStack',
    bool allowPinFallback = true,
  }) async {
    // 1. Check device capability
    final available = await isAvailable;
    if (!available) {
      return const BiometricNotAvailable(
        'Biometric authentication is not available on this device.',
      );
    }

    // 2. Attempt authentication
    try {
      final success = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: !allowPinFallback,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      return success
          ? const BiometricSuccess()
          : const BiometricFailure('Authentication failed. Please try again.');
    } on Exception catch (e) {
      // local_auth throws PlatformException with specific error codes
      final msg = e.toString();

      if (msg.contains('NotEnrolled')) {
        return const BiometricNotAvailable(
          'No biometrics enrolled. Please set up Face ID, fingerprint, or PIN in Settings.',
        );
      }
      if (msg.contains('LockedOut') || msg.contains('PermanentlyLockedOut')) {
        return const BiometricFailure(
          'Too many failed attempts. Please try again later.',
        );
      }
      if (msg.contains('UserCancel') || msg.contains('SystemCancel')) {
        return const BiometricFailure('Authentication cancelled.');
      }

      return BiometricError('Authentication error: $e');
    }
  }

  /// Cancels any in-progress authentication prompt.
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
