import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:medi_remind/auth/auth_service.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';
import 'add_edit_medication_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeOverviewTab(),
    const MedicationListTab(),
    const _PlaceholderTab(label: 'Alerts'),
    const DynamicProfileTab(),
  ];

  final List<String> _titles = const [
    'Home',
    'Medications',
    'Alerts',
    'Profile',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label\n(coming soon)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}

class HomeOverviewTab extends StatelessWidget {
  const HomeOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final MedicationService medicationService = MedicationService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: medicationService.getMedicationHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Center(child: Text('No history found yet.'));
              }
              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final DateTime takenAt = (item['takenAt'] as Timestamp)
                      .toDate();
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: Text('Took ${item['medicationName']}'),
                    subtitle: Text(
                      DateFormat('EEEE, MMM d • HH:mm').format(takenAt),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class MedicationListTab extends StatefulWidget {
  const MedicationListTab({super.key});

  @override
  State<MedicationListTab> createState() => _MedicationListTabState();
}

class _MedicationListTabState extends State<MedicationListTab> {
  final MedicationService _medicationService = MedicationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Medication>>(
        stream: _medicationService.getMedications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final medications = snapshot.data ?? [];
          if (medications.isEmpty) {
            return const Center(child: Text('No medications added yet.'));
          }
          return ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              final bool isTakenToday =
                  med.lastTaken != null &&
                  DateUtils.isSameDay(med.lastTaken, DateTime.now());

              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    isTakenToday
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isTakenToday ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _medicationService.markAsTaken(med),
                ),
                title: Text(
                  med.name,
                  style: TextStyle(
                    decoration: isTakenToday
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${med.dosage} - ${med.frequency}'),
                    if (med.reminderTimes.isNotEmpty)
                      Text(
                        'Reminders: ${med.reminderTimes.join(", ")}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    if (med.lastTaken != null)
                      Text(
                        'Last taken: ${DateFormat('MMM d, HH:mm').format(med.lastTaken!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditMedicationScreen(medication: med),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(med),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditMedicationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(Medication med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _medicationService.deleteMedication(med.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class DynamicProfileTab extends StatefulWidget {
  const DynamicProfileTab({super.key});

  @override
  State<DynamicProfileTab> createState() => _DynamicProfileTabState();
}

class _DynamicProfileTabState extends State<DynamicProfileTab> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _auth.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Text("Unable to load profile settings data."),
          );
        }

        var data = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Name: ${data['name']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${data['email']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Role: ${data['role'].toString().toUpperCase()}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile-settings');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Account Settings'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.missedColor,
                ),
                onPressed: () async {
                  await _auth.signOut();
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
