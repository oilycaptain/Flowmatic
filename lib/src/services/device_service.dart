import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/device_state.dart';
import '../models/reading.dart';

class DeviceService {
  DeviceService({this.deviceId = 'device1'});

  final String deviceId;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _deviceDoc => _db.collection('devices').doc(deviceId);

  Stream<DeviceState> deviceStateStream() {
    return _deviceDoc.snapshots().map((doc) => DeviceState.fromDoc(doc));
  }

  Stream<List<Reading>> readingsStream({int limit = 50}) {
    return _deviceDoc
        .collection('readings')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Reading.fromDoc(d)).toList());
  }

  Future<void> setPump(bool on) async {
    await _deviceDoc.set({'pumpOn': on, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await _sendCommand(type: 'PUMP', payload: {'on': on});
  }

  Future<void> setMode(String mode) async {
    await _deviceDoc.set({'mode': mode, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await _sendCommand(type: 'MODE', payload: {'mode': mode});
  }

  Future<void> setThresholdDry(int threshold) async {
    final t = threshold.clamp(0, 100);
    await _deviceDoc.set({'thresholdDry': t, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await _sendCommand(type: 'THRESHOLD', payload: {'thresholdDry': t});
  }

  Future<void> seedDemoData() async {
    // Creates a starter device doc + a few readings so the UI has something to show.
    await _deviceDoc.set({
      'soilMoisture': 42,
      'pumpOn': false,
      'mode': 'AUTO',
      'thresholdDry': 35,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final now = DateTime.now();
    final batch = _db.batch();
    final readings = [42, 39, 36, 34, 31, 37, 44];
    for (int i = 0; i < readings.length; i++) {
      final ref = _deviceDoc.collection('readings').doc();
      batch.set(ref, {
        'soilMoisture': readings[i],
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: i * 3))),
      });
    }
    await batch.commit();
  }

  Future<void> _sendCommand({required String type, required Map<String, dynamic> payload}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _deviceDoc.collection('commands').add({
      'type': type,
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });
  }
}
