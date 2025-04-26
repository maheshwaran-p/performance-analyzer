import 'package:flutter/material.dart';
import 'package:performance_analzer2/screens/auth/sign_up.dart';
import 'package:performance_analzer2/screens/auth/verify_email.dart';
import 'login.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/agni1.jpeg',
                  width: 250,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Certificate Analyzer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode 
                    ? 'Login to your account' 
                    : 'Create a new account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                // Conditional Rendering of Login or Signup
                _isLoginMode 
                  ? LoginScreen() 
                  : EmailVerificationScreen(),

                const SizedBox(height: 20),

                // Switch between Login and Signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode 
                        ? "Don't have an account? " 
                        : "Already have an account? ",
                    ),
                    GestureDetector(
                      onTap: _toggleAuthMode,
                      child: Text(
                        _isLoginMode ? 'Sign Up' : 'Login',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}