import 'package:flutter/foundation.dart';
import 'package:performance_analzer2/service/api_service.dart';

class User {
  final String name;
  final dynamic regNo; // Changed to dynamic to handle both string and int
  final String email;
  final dynamic phone; // Changed to dynamic to handle both string and int
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
      regNo: json['regNo'] ?? '', // Accept any type, will be converted to string when displayed
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '', // Accept any type, will be converted to string when displayed
      isHod: json['isHod'] ?? false,
    );
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
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await _apiService.login(email, password);
      
      if (response['success'] == true) {
        _currentUser = User.fromJson(response['userData']);
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
  
  void logout() {
    _currentUser = null;
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