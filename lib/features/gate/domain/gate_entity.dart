import 'package:geolocator/geolocator.dart';

enum GateStatus {
  idle,
  authenticating,
  authFailed,
  locating,
  locationDenied,
  ready,
}

class GateEntity {
  const GateEntity({
    this.status = GateStatus.idle,
    this.position,
    this.errorMessage,
    this.biometricLabel,
  });

  final GateStatus status;
  final Position?  position;
  final String?    errorMessage;
  final String?    biometricLabel;

  GateEntity copyWith({
    GateStatus? status,
    Position?   position,
    String?     errorMessage,
    String?     biometricLabel,
  }) => GateEntity(
    status:         status         ?? this.status,
    position:       position       ?? this.position,
    errorMessage:   errorMessage   ?? this.errorMessage,
    biometricLabel: biometricLabel ?? this.biometricLabel,
  );
}
