import 'package:cloud_firestore/cloud_firestore.dart';

class Reading {
  final int soilMoisture;
  final DateTime createdAt;

  const Reading({required this.soilMoisture, required this.createdAt});

  factory Reading.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawTs = data['createdAt'];
    final ts = rawTs is Timestamp ? rawTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);

    int moisture = 0;
    final rawMoisture = data['soilMoisture'];
    if (rawMoisture is int) moisture = rawMoisture;
    if (rawMoisture is double) moisture = rawMoisture.round();

    return Reading(soilMoisture: moisture.clamp(0, 100), createdAt: ts);
  }
}
