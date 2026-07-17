import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles caregiver alerts: detecting missed doses, sending FCM
/// notifications to caregivers, and logging alert history to Firestore.
class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates an alert document in Firestore when a dose is missed.
  /// This should be called by a scheduled check (e.g. a periodic
  /// background task or Cloud Function trigger) once a reminderTime
  /// has passed without the medication being marked as taken.
  Future<void> createMissedDoseAlert({
    required String patientId,
    required String caregiverId,
    required String medicationName,
  }) async {
    final alertRef = _firestore.collection('alerts').doc();

    await alertRef.set({
      'alertId': alertRef.id,
      'patientId': patientId,
      'caregiverId': caregiverId,
      'message': 'Missed dose: $medicationName was not taken as scheduled.',
      'type': 'missed_dose',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Streams all alerts for a specific caregiver, most recent first.
  /// Use this to populate the caregiver dashboard's alert history list.
  Stream<QuerySnapshot<Map<String, dynamic>>> getAlertsForCaregiver(
    String caregiverId,
  ) {
    return _firestore
        .collection('alerts')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Marks a single alert as read/acknowledged by the caregiver.
  Future<void> markAlertAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({'read': true});
  }

  /// Streams real-time medication adherence status for a given patient,
  /// used to power the caregiver's "monitor patient adherence" view.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPatientMedicationStatus(
    String patientId,
  ) {
    return _firestore
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .snapshots();
  }

  /// Fetches the caregiver's linked patient IDs from the caregiver's
  /// user document (assumes a 'linkedPatients' array field on the user doc).
  Future<List<String>> getLinkedPatientIds(String caregiverId) async {
    final doc = await _firestore.collection('users').doc(caregiverId).get();
    final data = doc.data();
    if (data == null || data['linkedPatients'] == null) return [];
    return List<String>.from(data['linkedPatients']);
  }

  /// Retrieves the FCM device token stored for a caregiver, so a Cloud
  /// Function (or this client, for testing) can target a push notification.
  Future<String?> getCaregiverFcmToken(String caregiverId) async {
    final doc = await _firestore.collection('users').doc(caregiverId).get();
    return doc.data()?['fcmToken'] as String?;
  }

  /// Saves this device's FCM token to the current user's document.
  /// Call this once on app start (after login) so caregivers can
  /// receive push notifications on this device.
  Future<void> saveFcmTokenForUser(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
