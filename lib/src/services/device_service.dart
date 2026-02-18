import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/device_state.dart';
import '../models/reading.dart';
import 'secure_command_codec.dart';

class DeviceService {
  DeviceService({
    this.deviceId = 'device1',
    FirebaseFirestore? firestore,
    SecureCommandCodec? codec,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _codec = codec ?? SecureCommandCodec();

  final String deviceId;
  final FirebaseFirestore _firestore;
  final SecureCommandCodec _codec;

  DocumentReference<Map<String, dynamic>> get _deviceDoc => _firestore.collection('devices').doc(deviceId);

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
    await _withRetry(() async {
      await _deviceDoc.set({'pumpOn': on, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await _sendCommand(type: 'PUMP', payload: {'on': on});
      await _writeDebugLog(event: 'pump_set', detail: {'pumpOn': on});
    });
  }

  Future<void> setMode(String mode) async {
    await _withRetry(() async {
      await _deviceDoc.set({'mode': mode, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await _sendCommand(type: 'MODE', payload: {'mode': mode});
      await _writeDebugLog(event: 'mode_set', detail: {'mode': mode});
      await evaluateAutomation();
    });
  }

  Future<void> setThresholdDry(int threshold) async {
    final t = threshold.clamp(0, 100);
    await _withRetry(() async {
      await _deviceDoc.set({'thresholdDry': t, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await _sendCommand(type: 'THRESHOLD', payload: {'thresholdDry': t});
      await _writeDebugLog(event: 'threshold_set', detail: {'thresholdDry': t});
      await evaluateAutomation();
    });
  }

  Future<void> addSensorReading(int soilMoisture, {DateTime? createdAt}) async {
    final safeMoisture = soilMoisture.clamp(0, 100);
    await _withRetry(() async {
      await _deviceDoc.collection('readings').add({
        'soilMoisture': safeMoisture,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt) : FieldValue.serverTimestamp(),
      });

      await _deviceDoc.set({
        'soilMoisture': safeMoisture,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _writeDebugLog(event: 'sensor_reading_ingested', detail: {'soilMoisture': safeMoisture});
      await evaluateAutomation();
    });
  }

  Future<void> evaluateAutomation() async {
    final snap = await _deviceDoc.get();
    final state = DeviceState.fromDoc(snap);

    if (state.mode != 'AUTO') {
      return;
    }

    final shouldPump = state.soilMoisture <= state.thresholdDry;
    if (shouldPump == state.pumpOn) {
      return;
    }

    await _deviceDoc.set({
      'pumpOn': shouldPump,
      'automationReason': shouldPump ? 'below_threshold' : 'recovered_moisture',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _sendCommand(
      type: 'AUTO_PUMP',
      payload: {
        'on': shouldPump,
        'soilMoisture': state.soilMoisture,
        'thresholdDry': state.thresholdDry,
      },
    );

    await _writeDebugLog(
      event: 'auto_irrigation_decision',
      detail: {
        'pumpOn': shouldPump,
        'soilMoisture': state.soilMoisture,
        'thresholdDry': state.thresholdDry,
      },
    );
  }

  Future<void> seedDemoData() async {
    await _withRetry(() async {
      await _deviceDoc.set({
        'soilMoisture': 42,
        'pumpOn': false,
        'mode': 'AUTO',
        'thresholdDry': 35,
        'securityMode': _codec.hasConfiguredKey ? 'ENCRYPTED' : 'SIGNED_PLAINTEXT',
        'transport': 'TLS_FIRESTORE',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final now = DateTime.now();
      final batch = _firestore.batch();
      final readings = [42, 39, 36, 34, 31, 37, 44];
      for (int i = 0; i < readings.length; i++) {
        final ref = _deviceDoc.collection('readings').doc();
        batch.set(ref, {
          'soilMoisture': readings[i],
          'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: i * 3))),
        });
      }
      await batch.commit();
      await _writeDebugLog(event: 'seed_demo_data', detail: {'readings': readings.length});
      await evaluateAutomation();
    });
  }

  Future<void> _sendCommand({required String type, required Map<String, dynamic> payload}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final encodedPayload = await _codec.encode(payload);
    await _deviceDoc.collection('commands').add({
      'type': type,
      'payload': encodedPayload,
      'transport': 'TLS_FIRESTORE',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });
  }

  Future<void> _writeDebugLog({required String event, required Map<String, dynamic> detail}) async {
    await _deviceDoc.collection('logs').add({
      'event': event,
      'detail': detail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _withRetry(Future<void> Function() action, {int attempts = 3}) async {
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        await action();
        return;
      } catch (e) {
        lastError = e;
        if (i < attempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 300 * (i + 1)));
        }
      }
    }

    if (lastError != null) {
      throw lastError!;
    }
  }
}
