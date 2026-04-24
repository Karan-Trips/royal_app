import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:royal_app/features/history/data/ride_repository.dart';
import 'package:royal_app/features/history/domain/ride_entity.dart';

part 'history_provider.g.dart';

// ── Ride History ──────────────────────────────────────────────────────────────

@riverpod
class RideHistoryNotifier extends _$RideHistoryNotifier {
  @override
  Future<List<RideEntity>> build() => RideRepository.instance.fetchRides();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(RideRepository.instance.fetchRides);
  }

  Future<void> saveAndRefresh({
    required List<LatLng> points,
    required double distanceKm,
    required double cost,
    required int durationSeconds,
    required double maxSpeedKmh,
    required double avgSpeedKmh,
  }) async {
    await RideRepository.instance.saveRide(
      points: points,
      distanceKm: distanceKm,
      cost: cost,
      durationSeconds: durationSeconds,
      maxSpeedKmh: maxSpeedKmh,
      avgSpeedKmh: avgSpeedKmh,
    );
    await refresh();
  }
}

// ── Bike Color ────────────────────────────────────────────────────────────────

const _colorTextureMap = {
  0xFF1565C0: 'body_blue',
  0xFFCC1100: 'body_red',
  0xFF1A1A1A: 'body_black',
};

@riverpod
class BikeColorNotifier extends _$BikeColorNotifier {
  @override
  Color build() => const Color(0xFFCC1100);

  void changeColor(Color color, Flutter3DController controller) {
    state = color;
    final textureName = _colorTextureMap[color.toARGB32()];
    if (textureName != null) {
      controller.setTexture(textureName: textureName);
    }
  }
}
