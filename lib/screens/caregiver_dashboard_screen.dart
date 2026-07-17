import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/alert_service.dart';

/// Main dashboard for caregivers: shows linked patients' medication
/// adherence status and a real-time feed of missed-dose alerts.
class CaregiverDashboardScreen extends StatefulWidget {
  final String caregiverId;

  const CaregiverDashboardScreen({super.key, required this.caregiverId});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _alertService.saveFcmTokenForUser(widget.caregiverId);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caregiver Dashboard'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _logout(context);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'logout', child: Text('Log out')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.medication), text: 'Adherence'),
              Tab(icon: Icon(Icons.notifications_active), text: 'Alerts'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildAdherenceTab(), _buildAlertsTab()]),
      ),
    );
  }

  Widget _buildAdherenceTab() {
    return FutureBuilder<List<String>>(
      future: _alertService.getLinkedPatientIds(widget.caregiverId),
      builder: (context, patientSnapshot) {
        if (patientSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final patientIds = patientSnapshot.data ?? [];
        if (patientIds.isEmpty) {
          return const Center(child: Text('No linked patients yet.'));
        }

        return ListView.builder(
          itemCount: patientIds.length,
          itemBuilder: (context, index) {
            return _PatientAdherenceCard(
              patientId: patientIds[index],
              alertService: _alertService,
            );
          },
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _alertService.getAlertsForCaregiver(widget.caregiverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data?.docs ?? [];
        if (alerts.isEmpty) {
          return const Center(child: Text('No alerts yet.'));
        }

        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index].data();
            final timestamp = alert['timestamp'] as Timestamp?;
            final isRead = alert['read'] == true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isRead ? null : Colors.red.shade50,
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: isRead ? Colors.grey : Colors.red,
                ),
                title: Text(alert['message'] ?? 'Alert'),
                subtitle: Text(
                  timestamp != null
                      ? DateFormat(
                          'EEEE, MMM d • HH:mm',
                        ).format(timestamp.toDate())
                      : 'Just now',
                ),
                trailing: isRead
                    ? null
                    : TextButton(
                        onPressed: () {
                          _alertService.markAlertAsRead(alerts[index].id);
                        },
                        child: const Text('Mark read'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Card showing a single patient's medication list with taken/missed status.
class _PatientAdherenceCard extends StatelessWidget {
  final String patientId;
  final AlertService alertService;

  const _PatientAdherenceCard({
    required this.patientId,
    required this.alertService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: alertService.getPatientMedicationStatus(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }

        final meds = snapshot.data?.docs ?? [];

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: $patientId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (meds.isEmpty) const Text('No medications recorded.'),
                ...meds.map((doc) {
                  final med = doc.data();
                  final lastTaken = (med['lastTaken'] as Timestamp?)?.toDate();
                  final takenToday =
                      lastTaken != null &&
                      DateTime.now().difference(lastTaken).inHours < 24;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      takenToday ? Icons.check_circle : Icons.cancel,
                      color: takenToday ? Colors.green : Colors.red,
                    ),
                    title: Text(med['name'] ?? 'Unknown medication'),
                    subtitle: Text(
                      takenToday
                          ? 'Dosage: ${med['dosage'] ?? '-'} • Taken today'
                          : 'Dosage: ${med['dosage'] ?? '-'} • Not taken yet today',
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
