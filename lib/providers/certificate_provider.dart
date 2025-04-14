import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/certificate.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class CertificateAuthenticationService {
  Future<Map<String, dynamic>> authenticateCertificate(File file) async {
    try {
      // Perform text recognition
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Combine all recognized text
      String extractedText = recognizedText.text.toLowerCase();

      // Validation criteria
      bool hasCertificateText = _checkCertificateText(extractedText);
      bool hasStructuredLayout = _checkDocumentLayout(recognizedText);
      bool hasOfficialElements = _checkOfficialElements(extractedText);

      // Cleanup
      await textRecognizer.close();

      // Create reasons and determine authenticity
      List<String> reasons = [];
      if (hasCertificateText) reasons.add('Contains certificate text');
      if (hasStructuredLayout) reasons.add('Structured document layout');
      if (hasOfficialElements) reasons.add('Official document indicators');

      return {
        'isOriginal': hasCertificateText && 
                      hasStructuredLayout && 
                      hasOfficialElements,
        'reason': reasons.isNotEmpty 
          ? reasons.join('. ') 
          : 'Unable to validate certificate',
        'certificateType': _identifyCertificateType(extractedText)
      };
    } catch (e) {
      return {
        'isOriginal': false,
        'reason': 'Error processing document: ${e.toString()}',
        'certificateType': 'Unknown'
      };
    }
  }

  bool _checkCertificateText(String text) {
    final certificateKeywords = [
      'certificate',
      'certified',
      'verification',
      'diploma',
      'degree',
      'award',
      'license'
    ];
    return certificateKeywords.any((keyword) => text.contains(keyword));
  }

  bool _checkDocumentLayout(RecognizedText recognizedText) {
    // Check for multiple text blocks typical in certificates
    return recognizedText.blocks.length >= 3;
  }

  bool _checkOfficialElements(String text) {
    final officialIndicators = [
      'issued by',
      'authorized',
      'official',
      'validated',
      'signature',
      'seal',
      'stamp'
    ];
    return officialIndicators.any((indicator) => text.contains(indicator));
  }

  String _identifyCertificateType(String text) {
    final certificateTypes = {
      'Academic': ['degree', 'diploma', 'graduation', 'university', 'college'],
      'Professional': ['license', 'certification', 'qualification', 'professional'],
      'Achievement': ['award', 'honor', 'recognition', 'achievement','completion']
    };

    for (var type in certificateTypes.entries) {
      if (type.value.any((keyword) => text.contains(keyword))) {
        return type.key;
      }
    }

    return 'Unidentified';
  }
}

class CertificateProvider extends ChangeNotifier {
  final CertificateAuthenticationService authService;

  CertificateProvider(this.authService);

  List<Certificate> _certificates = [];
  List<dynamic> _results = [];
  Set<String> _allRecommendations = {};
  bool _isLoading = false;
  int _averageScore = 0;

  List<Certificate> get certificates => _certificates;
  List<dynamic> get results => _results;
  Set<String> get allRecommendations => _allRecommendations;
  bool get isLoading => _isLoading;
  int get averageScore => _averageScore;

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


  int _calculateScore(bool isOriginal) {
    return isOriginal ? 85 : 40;
  }


    void _generateRecommendations() {
    _allRecommendations.clear();

    // if (_averageScore < 50) {
      _allRecommendations.add('Carefully verify the authenticity of your certificates.');
      _allRecommendations.add('Ensure certificates contain clear, official text and layout.');
    // }

    final invalidCount = _results.where((r) => !r['isOriginal']).length;
    // if (invalidCount > 0) {
      _allRecommendations.add('Some certificates failed validation. Consider getting official copies.');
    // }

    final certificateTypes = _results.map((r) => r['certificateType']).toSet();
    // if (certificateTypes.length > 1) {
      _allRecommendations.add('Certificates from different domains may require specialized verification.');
    // }
  }


  // void _calculateAverageScore() {
  //   if (_results.isEmpty) {
  //     _averageScore = 0;
  //     return;
  //   }

  //   final scores = _results.map((r) => r['score'] as int);
  //   _averageScore = (scores.reduce((a, b) => a + b) / _results.length).round();
  // }

  // void _generateRecommendations() {
  //   _allRecommendations.clear();

  //   if (_averageScore < 50) {
  //     _allRecommendations.add('Carefully verify the authenticity of your certificates.');
  //     _allRecommendations.add('Consider consulting official sources to confirm certificate validity.');
  //   }

  //   final pdfCount = _results.where((r) => r['type'] == 'pdf').length;
  //   final imageCount = _results.where((r) => ['jpg', 'jpeg', 'png'].contains(r['type'])).length;
    
  //   if (pdfCount > 0 && imageCount == 0) {
  //     _allRecommendations.add('Consider having image copies of your PDF certificates for additional verification.');
  //   }

  //   final forgedCount = _results.where((r) => r['isOriginal'] == false).length;
  //   if (forgedCount > 0) {
  //     _allRecommendations.add('Some certificates appear to have authenticity issues. Seek verification from issuing authorities.');
  //   }

  //   if (_averageScore < 70) {
  //     _allRecommendations.add('Your certificates may need additional validation. Consult with professional verification services.');
  //   }
  // }
}