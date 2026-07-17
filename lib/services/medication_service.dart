import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get medications for the current user
  Stream<List<Medication>> getMedications() {
    String uid = _auth.currentUser!.uid;
    return _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList());
  }

  // Add medication
  Future<void> addMedication(Medication medication) async {
    String uid = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .add(medication.toFirestore());
  }

  // Update medication
  Future<void> updateMedication(Medication medication) async {
    String uid = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medication.id)
        .update(medication.toFirestore());
  }

  // Delete medication
  Future<void> deleteMedication(String medicationId) async {
    String uid = _auth.currentUser!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medicationId)
        .delete();
  }

  // Mark medication as taken and record in history
  Future<void> markAsTaken(Medication medication) async {
    String uid = _auth.currentUser!.uid;
    DateTime now = DateTime.now();

    // 1. Update the lastTaken field in the medication document
    await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .doc(medication.id)
        .update({
      'lastTaken': Timestamp.fromDate(now),
    });

    // 2. Add a new record to the medication_history collection
    await _db
        .collection('users')
        .doc(uid)
        .collection('medication_history')
        .add({
      'medicationId': medication.id,
      'medicationName': medication.name,
      'takenAt': Timestamp.fromDate(now),
    });
  }

  // Get medication history
  Stream<List<Map<String, dynamic>>> getMedicationHistory() {
    String uid = _auth.currentUser!.uid;
    return _db
        .collection('users')
        .doc(uid)
        .collection('medication_history')
        .orderBy('takenAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
