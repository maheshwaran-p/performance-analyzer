import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:performance_analzer2/screens/auth/login.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isOTPSent = false;
  bool _isOTPVerified = false;
  bool _isLoading = false;

  // Skills and Education
  final List<TextEditingController> _skillControllers = [];
  final List<TextEditingController> _educationControllers = [];

  final String baseUrl = 'https://script.google.com/macros/s/AKfycbwuLlmlyZ5jS8Ee3lT9sJjIGOLoa4mOJpAYzEv3i2hwhR8MNNBBf141akzPJIJRv8sMFA/exec';
  @override
  void initState() {
    super.initState();
    // Start with one skill and education field
    _addSkillField();
    _addEducationField();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _regNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();

    // Dispose dynamic controllers
    for (var controller in _skillControllers) {
      controller.dispose();
    }
    for (var controller in _educationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSkillField() {
    setState(() {
      _skillControllers.add(TextEditingController());
    });
  }

  void _removeSkillField(int index) {
    setState(() {
      _skillControllers[index].dispose();
      _skillControllers.removeAt(index);
    });
  }

  void _addEducationField() {
    setState(() {
      _educationControllers.add(TextEditingController());
    });
  }

  void _removeEducationField(int index) {
    setState(() {
      _educationControllers[index].dispose();
      _educationControllers.removeAt(index);
    });
  }

  bool _validateEmail() {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter an email', isError: true);
      return false;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email', isError: true);
      return false;
    }
    
    return true;
  }

  Future<void> _sendOTP() async {
  final email = _emailController.text.trim().toLowerCase();

  if (!_validateEmail()) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse('$baseUrl?action=sendOTP&email=$email'),
    );

    final result = json.decode(response.body);
    
    if (result['success']) {
      setState(() {
        _isOTPSent = true;
        _isLoading = false;
      });
      _showSnackBar('OTP sent successfully', isError: false);
    } else {
      _showSnackBar(result['error'] ?? 'Failed to send OTP', isError: true);
    }
  } catch (e) {
    _showSnackBar('Error sending OTP: $e', isError: true);
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter OTP', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=verifyOTP&email=${_emailController.text.trim()}&otp=${_otpController.text}'),
      );

      final result = json.decode(response.body);
      
      if (result['success']) {
        setState(() {
          _isOTPVerified = true;
          _isLoading = false;
        });
        _showSnackBar('OTP verified successfully', isError: false);
      } else {
        _showSnackBar(result['error'] ?? 'OTP verification failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error verifying OTP: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signup() async {
  if (!_formKey.currentState!.validate()) return;

  // Validate password match
  if (_passwordController.text != _confirmPasswordController.text) {
    _showSnackBar('Passwords do not match', isError: true);
    return;
  }

  // Collect skills and education
  final skills = _skillControllers
      .map((controller) => controller.text.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

  final education = _educationControllers
      .map((controller) => controller.text.trim())
      .where((edu) => edu.isNotEmpty)
      .toList();

  setState(() {
    _isLoading = true;
  });

  final client = http.Client();

  try {
    // Initial signup request
    final initialResponse = await client.post(
      Uri.parse(baseUrl),
      body: json.encode({
        'action': 'signUp',
        'signupData': {
          'name': _nameController.text.trim(),
          'regNo': _regNoController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'skills': skills.join(', '),
          'education': education.join('; '),
        }
      }),
      headers: {'Content-Type': 'application/json'},
    );

    // Check if it's a redirect
    if (initialResponse.statusCode == 302) {
      // Get the redirect URL from the 'location' header
      final redirectUrl = initialResponse.headers['location'];
      
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await client.get(
          Uri.parse(redirectUrl)
        );

        // Process the redirected response
        final result = json.decode(redirectResponse.body);
        
        if (result['success']) {
          _showSnackBar('Signup successful', isError: false);
          
          // Navigate to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          _showSnackBar(result['error'] ?? 'Signup failed', isError: true);
        }
      } else {
        _showSnackBar('Redirect URL not found', isError: true);
      }
    } else if (initialResponse.statusCode == 200) {
      // If not a redirect, process the response normally
      final result = json.decode(initialResponse.body);
      
      if (result['success']) {
        _showSnackBar('Signup successful', isError: false);
        
        // Navigate to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _showSnackBar(result['error'] ?? 'Signup failed', isError: true);
      }
    } else {
      _showSnackBar('Signup failed: ${initialResponse.statusCode}', isError: true);
    }
  } catch (e) {
    _showSnackBar('Error during signup: $e', isError: true);
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: 
           Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Personal Information
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _regNoController,
            decoration: InputDecoration(
              labelText: 'Registration Number',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your registration number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email and Phone
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              // suffixIcon: _isOTPSent && !_isOTPVerified
              //     ? null
              //     : IconButton(
              //         icon: const Icon(Icons.send),
              //         onPressed: _sendOTP,
              //       ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // OTP Verification
          if (_isOTPSent && !_isOTPVerified)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: const Icon(Icons.verified_user),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter OTP';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Verify'),
                ),
              ],
            ),
          if (_isOTPSent && !_isOTPVerified)
            const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              final phoneRegex = RegExp(r'^\d{10}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible 
                    ? Icons.visibility_off 
                    : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible 
                    ? Icons.visibility_off 
                    : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Skills Section
          _buildDynamicSection(
            title: 'Skills',
            controllers: _skillControllers,
            onAdd: _addSkillField,
            onRemove: _removeSkillField,
            hintText: 'Enter a skill',
          ),
          const SizedBox(height: 16),

          // Education Section
          _buildDynamicSection(
            title: 'Education',
            controllers: _educationControllers,
            onAdd: _addEducationField,
            onRemove: _removeEducationField,
            hintText: 'Enter education details',
          ),
          const SizedBox(height: 16),

          // Signup Button
          ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    ))));
  }

  Widget _buildDynamicSection({
  required String title,
  required List<TextEditingController> controllers,
  required VoidCallback onAdd,
  required Function(int) onRemove,
  required String hintText,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAdd,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...List.generate(controllers.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (controllers.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => onRemove(index),
                ),
            ],
          ),
        );
      }),
    ],
  );
}
}