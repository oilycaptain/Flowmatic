import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceState {
  final int soilMoisture;
  final bool pumpOn;
  final String mode; // AUTO / MANUAL
  final int thresholdDry;
  final DateTime? lastUpdated;

  const DeviceState({
    required this.soilMoisture,
    required this.pumpOn,
    required this.mode,
    required this.thresholdDry,
    required this.lastUpdated,
  });

  static DeviceState empty() {
    return const DeviceState(
      soilMoisture: 0,
      pumpOn: false,
      mode: 'AUTO',
      thresholdDry: 35,
      lastUpdated: null,
    );
  }

  factory DeviceState.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return DeviceState.empty();

    DateTime? ts;
    final rawTs = data['lastUpdated'];
    if (rawTs is Timestamp) ts = rawTs.toDate();

    return DeviceState(
      soilMoisture: _toInt(data['soilMoisture'], fallback: 0).clamp(0, 100),
      pumpOn: (data['pumpOn'] as bool?) ?? false,
      mode: (data['mode'] as String?) ?? 'AUTO',
      thresholdDry: _toInt(data['thresholdDry'], fallback: 35).clamp(0, 100),
      lastUpdated: ts,
    );
  }

  static int _toInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
