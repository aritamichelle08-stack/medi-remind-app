import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/home_screen.dart';
import '../screens/caregiver_dashboard_screen.dart';
import '../auth/auth_screen.dart';
import 'package:medi_remind/screens/profile_settings_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/splash': (context) => const SplashScreen(),
    '/onboarding': (context) => const OnboardingScreen(),
    '/welcome': (context) => const WelcomeScreen(),
    '/patient-login': (context) => const AuthScreen(initialRole: 'patient'),
    '/caregiver-login': (context) => const AuthScreen(initialRole: 'caregiver'),
    '/home': (context) => const HomeScreen(),
    '/caregiver-dashboard': (context) => CaregiverDashboardScreen(
      caregiverId: FirebaseAuth.instance.currentUser!.uid,
    ),
    '/profile-settings': (context) => const ProfileSettingsScreen(),
  };
}
