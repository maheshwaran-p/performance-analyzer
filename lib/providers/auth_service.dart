import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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