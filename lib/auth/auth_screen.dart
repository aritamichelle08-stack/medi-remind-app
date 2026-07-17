import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  final String initialRole; // 'patient' or 'caregiver' Passed by Person 1
  const AuthScreen({super.key, required this.initialRole});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;

  // Background shading that matches a clean interface profile
  static const Color fbBg = Color(0xFFF0F2F5);

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: widget.initialRole,
        );
      } else {
        await _authService.loginWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      final destination = widget.initialRole == 'caregiver'
          ? '/caregiver-dashboard'
          : '/home';
      Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
    } on FirebaseAuthException catch (e) {
      // Intercepts general credential message to give explicit wrong password feedback
      String feedbackMessage = "An authentication error occurred.";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        feedbackMessage = "Wrong password. Please try again.";
      } else if (e.code == 'user-not-found') {
        feedbackMessage = "No user found with this email.";
      } else if (e.message != null) {
        feedbackMessage = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackMessage),
          backgroundColor:
              AppTheme.missedColor, // Uses theme missed/error color
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.missedColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email!'),
          backgroundColor: AppTheme.takenColor, // Uses theme success color
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.missedColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fbBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Facebook style typographic header branded using Project Theme color
                        const Text(
                          'mediremind',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.initialRole.toUpperCase()} PORTAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login Card Block
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Full name',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'What\'s your name?' : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Mobile number or email address',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                validator: (v) => v!.isEmpty || !v.contains('@')
                                    ? 'Enter a valid email address.'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                validator: (v) => v!.length < 6
                                    ? 'Password must be at least 6 characters.'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Main Submission Action Button (Primary Theme Color)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: _submitForm,
                                child: Text(
                                  _isSignUp ? 'Sign Up' : 'Log In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Forgot Password Action Link
                              if (!_isSignUp) ...[
                                TextButton(
                                  onPressed: _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    splashFactory: NoSplash.splashFactory,
                                  ),
                                  child: const Text(
                                    'Forgotten password?',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Visual Context Splitter Line
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade400),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Secondary Alternative Action Button (Taken Green Theme Color)
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.takenColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Text(
                                _isSignUp
                                    ? 'Back to Log In'
                                    : 'Create New Account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
