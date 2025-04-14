import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:performance_analzer2/providers/auth_service.dart';
import 'package:performance_analzer2/service/api_service.dart';
import 'dart:convert';
import '../models/certificate.dart';

class CertificateProvider extends ChangeNotifier {
  final CertificateAuthenticationService authService;
  final ApiService _apiService = ApiService();

  CertificateProvider(this.authService);

  List<Certificate> _certificates = [];
  List<dynamic> _results = [];
  List<dynamic> _serverCertificates = []; // Certificates from the server
  Set<String> _allRecommendations = {};
  bool _isLoading = false;
  int _averageScore = 0;
  String? _currentUserEmail;

  List<Certificate> get certificates => _certificates;
  List<dynamic> get results => _results;
  List<dynamic> get serverCertificates => _serverCertificates;
  Set<String> get allRecommendations => _allRecommendations;
  bool get isLoading => _isLoading;
  int get averageScore => _averageScore;

  // Set current user email from login
  void setCurrentUser(String email) {
    _currentUserEmail = email;
  }

  // Load server certificates
  Future<void> loadServerCertificates() async {
    if (_currentUserEmail == null) {
      return;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      _serverCertificates = await _apiService.getCertificates(_currentUserEmail!);
      
      // Calculate the average score based on server certificates
      if (_serverCertificates.isNotEmpty) {
        final scores = _serverCertificates.map((cert) => cert['Score'] as int? ?? 0);
        _averageScore = (scores.reduce((a, b) => a + b) / _serverCertificates.length).round();
      }
      
    } catch (e) {
      print('Error loading server certificates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickFiles() async {
    try {
      _isLoading = true;
      notifyListeners();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        List<Certificate> newCertificates = result.files.map((file) {
          return Certificate(
            filename: file.name,
            fileType: file.extension ?? '',
            file: File(file.path!),
          );
        }).toList();

        // Add new certificates, avoiding duplicates
        for (var newCert in newCertificates) {
          if (!_certificates.any((cert) => cert.filename == newCert.filename)) {
            _certificates.add(newCert);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking files: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Add this method to your CertificateProvider class

Future<bool> saveValidCertificates(String email) async {
  try {
    _isLoading = true;
    notifyListeners();
    
    // Filter only valid certificates
    final validCertificates = _certificates.where((cert) => cert.isOriginal == true).toList();
    
    if (validCertificates.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    // Save certificates to the server
    final success = await _apiService.saveCertificates(email, validCertificates);
    
    if (success) {
      // Reload server certificates to update the list
      await loadServerCertificates();
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  } catch (e) {
    print('Error saving valid certificates: $e');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
  void removeCertificate(int index) {
    if (index >= 0 && index < _certificates.length) {
      _certificates.removeAt(index);
      notifyListeners();
    }
  }

  void clearCertificates() {
    _certificates.clear();
    _results.clear();
    _averageScore = 0;
    _allRecommendations.clear();
    notifyListeners();
  }

  Future<void> analyzeCertificates() async {
    try {
      _isLoading = true;
      _results.clear();
      _allRecommendations.clear();
      notifyListeners();

      for (var certificate in _certificates) {
        try {
          final authResult = await authService.authenticateCertificate(certificate.file);
          
          // Determine if certificate is valid based on type
          final certificateType = authResult['certificateType'] ?? 'Unknown';
          final isValid = certificateType != 'Unidentified';
          
          // Calculate score based on validity
          int score = 0; // Default score for invalid certificates
          
          // Only calculate score if the certificate is valid
          if (isValid) {
            score = 85;  // Base score for valid certificate types
            
            // Add additional score points if it passes other validations 
            if (authResult['isOriginal'] == true) {
              score += 15;
            }
          }
          
          final result = {
            'filename': certificate.filename,
            'type': certificate.fileType,
            'score': score,
            'isOriginal': isValid, // Based on certificate type
            'authenticationReason': isValid 
                ? 'Valid ${certificateType} certificate identified' 
                : 'Certificate type could not be determined',
            'certificateType': certificateType
          };
          
          // Update the certificate object with validation results
          certificate.isOriginal = isValid;
          certificate.authenticationReason = isValid 
              ? 'Valid ${certificateType} certificate identified' 
              : 'Certificate type could not be determined';
          
          _results.add(result);
        } catch (e) {
          _results.add({
            'filename': certificate.filename,
            'type': certificate.fileType,
            'score': 0,
            'isOriginal': false,
            'authenticationReason': 'Authentication failed: $e',
            'certificateType': 'Unknown'
          });
        }
      }

      _calculateAverageScore();
      _generateRecommendations();
      
      // Save certificates to server if user is logged in
      if (_currentUserEmail != null) {
        await _apiService.saveCertificates(_currentUserEmail!, _certificates);
        // Reload server certificates after saving
        await loadServerCertificates();
      }
      
    } catch (e) {
      print('Error in analyzeCertificates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateAverageScore() {
    if (_results.isEmpty) {
      _averageScore = 0;
      return;
    }

    final scores = _results.map((r) => r['score'] as int);
    _averageScore = (scores.reduce((a, b) => a + b) / _results.length).round();
  }

  void _generateRecommendations() {
    _allRecommendations.clear();

    _allRecommendations.add('Carefully verify the authenticity of your certificates.');
    _allRecommendations.add('Ensure certificates contain clear, official text and layout.');
    _allRecommendations.add('Some certificates failed validation. Consider getting official copies.');
    _allRecommendations.add('Certificates from different domains may require specialized verification.');
  }
}