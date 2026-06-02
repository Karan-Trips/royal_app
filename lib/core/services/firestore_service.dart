import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Central Firestore access point.
///
/// Collections are scoped under `devices/{deviceId}/` so data is isolated
/// per device without requiring Firebase Auth.
/// Offline persistence is enabled in main.dart via [FirebaseFirestore.settings].
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Device ID ─────────────────────────────────────────────────────────────
  // Set once from main() after HiveService.init() reads the persisted ID.
  String _deviceId = 'default';

  void setDeviceId(String id) => _deviceId = id;
  String get deviceId => _deviceId;

  // ── Collection refs ───────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get rides =>
      _db.collection('devices').doc(_deviceId).collection('rides');

  CollectionReference<Map<String, dynamic>> get fuelEntries =>
      _db.collection('devices').doc(_deviceId).collection('fuel_entries');

  DocumentReference<Map<String, dynamic>> get statsDoc =>
      _db.collection('devices').doc(_deviceId);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Batch write — use for atomic multi-doc updates.
  WriteBatch batch() => _db.batch();

  /// Enable offline persistence (call once before any Firestore usage).
  static Future<void> enableOfflinePersistence() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('[Firestore] persistence already configured: $e');
    }
  }
}
