import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';

class User {
  final String name;
  final dynamic regNo;
  final String email;
  final dynamic phone;
  final bool isHod;

  User({
    required this.name,
    required this.regNo,
    required this.email,
    required this.phone,
    required this.isHod,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name']?.toString() ?? '',
      regNo: json['regNo'] ?? '', 
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '', 
      isHod: json['isHod'] ?? false,
    );
  }

  // Convert user to JSON for saving in SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'regNo': regNo,
      'email': email,
      'phone': phone,
      'isHod': isHod,
    };
  }

  // Helper methods to get regNo and phone as strings when needed
  String get regNoAsString => regNo?.toString() ?? '';
  String get phoneAsString => phone?.toString() ?? ''; 
}

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProvider() {
    // Try to load user from SharedPreferences on initialization
    _loadUserFromPrefs();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Load user from SharedPreferences
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    
    if (userJson != null) {
      try {
        // Recreate user from saved JSON
        final userData = User.fromJson(Map<String, dynamic>.from(
          json.decode(userJson)
        ));
        _currentUser = userData;
        notifyListeners();
      } catch (e) {
        print('Error loading user from prefs: $e');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.login(email, password);

      if (response['success'] == true) {
        // Create user from response
        _currentUser = User.fromJson(response['userData']);
        
        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(_currentUser!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Clear user data from provider
    _currentUser = null;
    
    // Clear user data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');
    await prefs.remove('user_password');
    
    notifyListeners();
  }

  Future<Map<String, dynamic>> getProfile() async {
    if (_currentUser == null) {
      return {};
    }

    try {
      return await _apiService.getStaffProfile(_currentUser!.email);
    } catch (e) {
      print('Error getting profile: $e');
      return {};
    }
  }
}