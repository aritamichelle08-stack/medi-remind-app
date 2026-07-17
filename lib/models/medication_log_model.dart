import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime takenAt;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.takenAt,
  });

  factory MedicationLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MedicationLog(
      id: doc.id,
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      takenAt: (data['takenAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'takenAt': Timestamp.fromDate(takenAt),
    };
  }
}
