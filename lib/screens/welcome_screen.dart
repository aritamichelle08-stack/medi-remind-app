import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.health_and_safety,
                size: 90,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Who are you?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to continue',
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: const Text(
                    "I'm a Patient",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/patient-login');
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(Icons.family_restroom, color: AppTheme.primaryColor),
                  label: Text(
                    "I'm a Caregiver",
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/caregiver-login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}