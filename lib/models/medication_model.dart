import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> reminderTimes; // Format: "HH:mm"
  final DateTime? nextDose;
  final DateTime? lastTaken;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.reminderTimes = const [],
    this.nextDose,
    this.lastTaken,
  });

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Medication(
      id: doc.id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      nextDose: (data['nextDose'] as Timestamp?)?.toDate(),
      lastTaken: (data['lastTaken'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'reminderTimes': reminderTimes,
      'nextDose': nextDose != null ? Timestamp.fromDate(nextDose!) : null,
      'lastTaken': lastTaken != null ? Timestamp.fromDate(lastTaken!) : null,
    };
  }
}
