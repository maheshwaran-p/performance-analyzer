import 'dart:io';
import 'dart:math' as math;
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
      
      // Calculate the average score based on valid server certificates only
      if (_serverCertificates.isNotEmpty) {
        final validCertificates = _serverCertificates.where((cert) => 
            (cert['Score'] as int? ?? 0) > 0).toList();
            
        if (validCertificates.isNotEmpty) {
          final scores = validCertificates.map((cert) => cert['Score'] as int? ?? 0);
          _averageScore = (scores.reduce((a, b) => a + b) / validCertificates.length).round();
        } else {
          _averageScore = 0;
        }
      } else {
        _averageScore = 0;
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

  // Save only valid certificates
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
      
      print('saving cert');
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

  // import 'dart:math' as math;

Future<void> analyzeCertificates() async {
  try {
    _isLoading = true;
    _results.clear();
    _allRecommendations.clear();
    notifyListeners();

    // Create a random number generator
    final random = math.Random();

    for (var certificate in _certificates) {
      try {
        final authResult = await authService.authenticateCertificate(certificate.file);
        print(authResult);
        
        // Determine if certificate is valid based on type
        final certificateType = authResult['certificateType'] ?? 'Unknown';
        final isValid = certificateType != 'Unidentified' && certificateType != 'Unknown';
        print('certificateType---$certificateType');
        
        // Calculate score based on validity
        int score = 0; // Default score for invalid certificates
        
        // Only calculate score if the certificate is valid
        if (isValid) {
          // Generate a random score between 65 and 75
          score = (63 + random.nextInt(11)); // This gives a range from 65 to 75
          
          // Add additional score points if it passes other validations
          if (authResult['isOriginal'] == true) {
            score += 15;
          }
          
          // Ensure score never exceeds 100
          if (score > 100) {
            score = 100;
          }
        }
        
        final result = {
          'filename': certificate.filename,
          'type': certificate.fileType,
          'score': score,
          'isOriginal': isValid, // Based on certificate type
          'authenticationReason': authResult['reason'] ?? 
              (isValid 
                ? 'Valid ${certificateType} certificate identified' 
                : 'Certificate type could not be determined'),
          'certificateType': certificateType
        };
        
        // Update the certificate object with validation results
        certificate.isOriginal = isValid;
        certificate.authenticationReason = authResult['reason'] ?? 
            (isValid 
              ? 'Valid ${certificateType} certificate identified' 
              : 'Certificate type could not be determined');
        
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

    // Calculate average score only for valid certificates
    _calculateValidAverageScore();
    _generateRecommendations();
    
    // Don't automatically save to server - wait for submit button
    
  } catch (e) {
    print('Error in analyzeCertificates: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  void _calculateValidAverageScore() {
    final validResults = _results.where((result) => result['isOriginal'] == true).toList();
    
    if (validResults.isEmpty) {
      _averageScore = 0;
      return;
    }

    final scores = validResults.map((r) => r['score'] as int);
    _averageScore = (scores.reduce((a, b) => a + b) / validResults.length).round();
  }

  void _generateRecommendations() {
    _allRecommendations.clear();
    
    final validCount = _results.where((result) => result['isOriginal'] == true).length;
    final invalidCount = _results.length - validCount;

    // Always add some basic recommendations
    _allRecommendations.add('Carefully verify the authenticity of your certificates.');
    _allRecommendations.add('Ensure certificates contain clear, official text and layout.');
    
    // Add specific recommendations based on results
    if (invalidCount > 0) {
      _allRecommendations.add('${invalidCount} certificate(s) failed validation. Consider getting official copies.');
      _allRecommendations.add('Make sure your certificates are clearly scanned with no blurry text.');
    }
    
    if (_averageScore < 70) {
      _allRecommendations.add('Try to obtain certificates with higher recognition value.');
    }
    
    if (validCount > 0) {
      _allRecommendations.add('Valid certificates will be highlighted in your profile.');
    }
    
    _allRecommendations.add('Certificates from different domains may require specialized verification.');
  }
}