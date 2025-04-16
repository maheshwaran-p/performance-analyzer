import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:performance_analzer2/service/constants.dart';
import '../models/certificate.dart';

class ApiService {
  // Replace with your deployed Google Apps Script Web App URL
  static  String baseUrl = Constants.baseUrl;
  
  // User authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=login&email=$email&password=$password'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Get certificates for a staff member
  Future<List<dynamic>> getCertificates(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=getCertificates&email=$email'),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return result['certificates'];
        } else {
          throw Exception(result['error'] ?? 'Failed to get certificates');
        }
      } else {
        throw Exception('Failed to get certificates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting certificates: $e');
      return [];
    }
  }
  
  // Get staff profile
  Future<Map<String, dynamic>> getStaffProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=getProfile&email=$email'),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('profile data -- ${result['profile']}');
          return result['profile'];
        } else {
          throw Exception(result['error'] ?? 'Failed to get profile');
        }
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      return {};
    }
  }
  
  // Save certificates
  Future<bool> saveCertificates(String email, List<Certificate> certificates) async {
    try {
      // First upload files to get URLs
      List<Map<String, dynamic>> certificateData = [];
      
      for (var cert in certificates) {
        // Convert certificates to the format expected by the API
        certificateData.add({
          'filename': cert.filename,
          'fileType': cert.fileType,
          'fileURL': await _uploadFile(cert.file, cert.filename),
          'score': cert.isOriginal == true ? 85 : 40,
          'isOriginal': cert.isOriginal ?? false,
          'certificateType': cert.authenticationReason ?? 'Unknown',
        });
      }
      
      // Send certificate data to Google Apps Script
      final response = await http.post(
        Uri.parse(baseUrl),
        body: jsonEncode({
          'action': 'saveCertificates',
          'email': email,
          'certificates': certificateData,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      } else {
        throw Exception('Failed to save certificates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving certificates: $e');
      return false;
    }
  }
  
  // Helper method to upload a file and get URL
  // This is a placeholder - in a real app, you'd implement file upload to storage
  Future<String> _uploadFile(File file, String filename) async {
    // For demonstration purposes, we're returning a placeholder URL
    // In a real app, you would upload to Google Drive or other storage
    return 'https://storage.example.com/certificates/$filename';
  }
  Future<bool> saveResearch(String email, Map<String, dynamic> research) async {
  try {
    final client = http.Client();
    
    // Initial POST request
    final initialResponse = await client.post(
      Uri.parse(baseUrl),
      body: jsonEncode({
        'action': 'saveResearch',
        'email': email,
        'research': research,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Check status code and handle redirect
    if (initialResponse.statusCode == 302) {
      final redirectUrl = initialResponse.headers['location'];
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await client.get(
          Uri.parse(redirectUrl)
        );

        // Process the redirected response
        if (redirectResponse.statusCode == 200) {
          final result = jsonDecode(redirectResponse.body);
          return result?['success'] ?? false;
        }
      }
    } else if (initialResponse.statusCode == 200) {
      final result = jsonDecode(initialResponse.body);
      return result?['success'] ?? false;
    }

    throw Exception('Failed to save research');
  } catch (e) {
    print('Error saving research: $e');
    return false;
  }
}

Future<bool> savePublication(String email, Map<String, dynamic> publication) async {
  try {
    final client = http.Client();
    
    // Initial POST request
    final initialResponse = await client.post(
      Uri.parse(baseUrl),
      body: jsonEncode({
        'action': 'savePublication',
        'email': email,
        'publication': publication,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Check status code and handle redirect
    if (initialResponse.statusCode == 302) {
      final redirectUrl = initialResponse.headers['location'];
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await client.get(
          Uri.parse(redirectUrl)
        );

        // Process the redirected response
        if (redirectResponse.statusCode == 200) {
          final result = jsonDecode(redirectResponse.body);
          return result?['success'] ?? false;
        }
      }
    } else if (initialResponse.statusCode == 200) {
      final result = jsonDecode(initialResponse.body);
      return result?['success'] ?? false;
    }

    throw Exception('Failed to save publication');
  } catch (e) {
    print('Error saving publication: $e');
    return false;
  }
}

Future<bool> saveSelfDevelopment(String email, Map<String, dynamic> selfDevelopment) async {
  try {
    final client = http.Client();
    
    // Initial POST request
    final initialResponse = await client.post(
      Uri.parse(baseUrl),
      body: jsonEncode({
        'action': 'saveSelfDevelopment',
        'email': email,
        'selfDevelopment': selfDevelopment,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Check status code and handle redirect
    if (initialResponse.statusCode == 302) {
      final redirectUrl = initialResponse.headers['location'];
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await client.get(
          Uri.parse(redirectUrl)
        );

        // Process the redirected response
        if (redirectResponse.statusCode == 200) {
          final result = jsonDecode(redirectResponse.body);
          return result?['success'] ?? false;
        }
      }
    } else if (initialResponse.statusCode == 200) {
      final result = jsonDecode(initialResponse.body);
      return result?['success'] ?? false;
    }

    throw Exception('Failed to save self development');
  } catch (e) {
    print('Error saving self development: $e');
    return false;
  }
}
  
Future<bool> saveGuestLecture(String email, Map<String, dynamic> guestLecture) async {
  try {
    final client = http.Client();
    
    // Initial POST request
    final initialResponse = await client.post(
      Uri.parse(baseUrl),
      body: jsonEncode({
        'action': 'saveGuestLecture',
        'email': email,
        'guestLecture': guestLecture,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_JWT_TOKEN'
      },
    );

    // Check status code and handle redirect
    if (initialResponse.statusCode == 302) {
      final redirectUrl = initialResponse.headers['location'];
      if (redirectUrl != null) {
        // Follow the redirect
        final redirectResponse = await client.get(
          Uri.parse(redirectUrl),
          headers: {
            // 'Authorization': 'Bearer YOUR_JWT_TOKEN'
          }
        );

        // Process the redirected response
        if (redirectResponse.statusCode == 200) {
          final result = jsonDecode(redirectResponse.body);
          return result['success'] == true;
        }
      }
    } else if (initialResponse.statusCode == 200) {
      final result = jsonDecode(initialResponse.body);
      return result['success'] == true;
    }

    throw Exception('Failed to save guest lecture');
  } catch (e) {
    print('Error saving guest lecture: $e');
    return false;
  }
}
  
}