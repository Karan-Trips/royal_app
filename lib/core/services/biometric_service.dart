import 'package:local_auth/local_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthResult — what came back from the authentication attempt
// ─────────────────────────────────────────────────────────────────────────────

enum AuthResult {
  /// User passed biometric / PIN successfully.
  success,

  /// User cancelled the prompt (tapped "Cancel" or pressed back).
  cancelled,

  /// Too many failed attempts — device is temporarily locked.
  lockedOut,

  /// Device has no biometrics / PIN set up at all.
  notAvailable,

  /// Something unexpected went wrong (platform error, etc.).
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// BiometricService — thin wrapper around local_auth
//
// Usage (anywhere in the app, no Riverpod needed):
//
//   final result = await BiometricService.instance.authenticate();
//
//   switch (result) {
//     case AuthResult.success:    // open the app
//     case AuthResult.cancelled:  // show retry button
//     case AuthResult.lockedOut:  // show "try later" message
//     case AuthResult.notAvailable: // skip biometric gate
//     case AuthResult.error:      // show generic error
//   }
// ─────────────────────────────────────────────────────────────────────────────

class BiometricService {
  // Private constructor — use BiometricService.instance everywhere.
  BiometricService._();

  /// Global singleton — one instance for the whole app lifetime.
  static final BiometricService instance = BiometricService._();

  // The underlying local_auth plugin instance.
  final _auth = LocalAuthentication();

  // ── Public helpers ──────────────────────────────────────────────────────────

  /// Returns true if the device can do biometric or PIN authentication.
  /// Safe to call at any time — never throws.
  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns a friendly label for the best available biometric.
  /// e.g. "Face ID", "Fingerprint", "Device PIN".
  Future<String> get biometricLabel async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face))        return 'Face ID';
      if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
      if (types.contains(BiometricType.iris))        return 'Iris Scan';
    } catch (_) {}
    return 'Device PIN';
  }

  // ── Core method ─────────────────────────────────────────────────────────────

  /// Shows the system biometric / PIN prompt and returns an [AuthResult].
  ///
  /// [reason] — the message shown inside the system prompt.
  /// [allowPin] — if true, user can fall back to PIN/pattern when biometrics fail.
  Future<AuthResult> authenticate({
    String reason   = 'Authenticate to access MotoStack',
    bool   allowPin = true,
  }) async {
    // 1. Bail early if the device has nothing set up.
    if (!await isAvailable) return AuthResult.notAvailable;

    try {
      final granted = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          // biometricOnly: false  → allows PIN fallback when allowPin is true
          biometricOnly:        !allowPin,
          stickyAuth:           true,  // keeps prompt alive if app goes background
          sensitiveTransaction: true,  // shows extra confirmation on some devices
        ),
      );

      // local_auth returns false when the user simply dismisses the prompt.
      return granted ? AuthResult.success : AuthResult.cancelled;

    } catch (e) {
      return _mapError(e.toString());
    }
  }

  /// Dismisses any currently visible authentication prompt.
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  /// Maps a local_auth PlatformException message to a clean [AuthResult].
  AuthResult _mapError(String message) {
    if (message.contains('NotEnrolled')) {
      // No biometrics / PIN enrolled on the device.
      return AuthResult.notAvailable;
    }
    if (message.contains('LockedOut') || message.contains('PermanentlyLockedOut')) {
      // Too many wrong attempts.
      return AuthResult.lockedOut;
    }
    if (message.contains('UserCancel') || message.contains('SystemCancel')) {
      // User tapped Cancel or the system dismissed the prompt.
      return AuthResult.cancelled;
    }
    // Anything else is an unexpected platform error.
    return AuthResult.error;
  }
}
