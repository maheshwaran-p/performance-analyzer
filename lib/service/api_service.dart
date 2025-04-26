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
      print('$baseUrl?action=getProfile&email=$email');
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
  
  Future<bool> saveCertificates(String email, List<Certificate> certificates) async {
  try {
    print('saving cert');
    // First upload files to get URLs
    List<Map<String, dynamic>> certificateData = [];
    
    for (var cert in certificates) {
      // Convert certificates to the format expected by the API
      certificateData.add({
        'filename': cert.filename,
        'fileType': cert.fileType,
        'fileURL': await _uploadFile(cert.file, cert.filename),
        'score': cert.isOriginal == true ? 85 : 0,
        'isOriginal': cert.isOriginal ?? false,
        'certificateType': cert.authenticationReason ?? 'Unknown',
      });
    }
    
    // Create the initial request
    final initialResponse = await http.post(
      Uri.parse(baseUrl),
      body: jsonEncode({
        'action': 'saveCertificates',
        'email': email,
        'certificates': certificateData,
      }),
      headers: {'Content-Type': 'application/json'},
      // followRedirects: false,
    );
    
    // Detailed logging for debugging
    print('Initial response status: ${initialResponse.statusCode}');
    print('Initial response headers: ${initialResponse.headers}');
    
    // Check if we got a redirect (status code 302)
    if (initialResponse.statusCode == 302 && initialResponse.headers.containsKey('location')) {
      // Get the redirect URL
      final redirectUrl = initialResponse.headers['location']!;
      print('Following redirect to: $redirectUrl');
      
      // For Google Apps Script, we need to use GET instead of POST for the redirect
      // This is a common issue with Apps Script web apps
      final redirectResponse = await http.get(
        Uri.parse(redirectUrl),
        headers: {
          'Accept': 'application/json',
        },
      );
      
      // Log detailed information about redirect response
      print('Redirect response status: ${redirectResponse.statusCode}');
      print('Redirect response headers: ${redirectResponse.headers}');
      print('Redirect response body: ${redirectResponse.body.substring(0, min(100, redirectResponse.body.length))}...');
      
      if (redirectResponse.statusCode == 200) {
        try {
          final result = jsonDecode(redirectResponse.body);
          return result['success'] == true;
        } catch (e) {
          print('Error parsing JSON from redirect response: $e');
          // Check if the body contains a success message even if not valid JSON
          return redirectResponse.body.contains('success') || 
                 redirectResponse.body.contains('saved');
        }
      } else {
        throw Exception('Failed after redirect: ${redirectResponse.statusCode}');
      }
    } 
    // If it's a 200 response, process normally
    else if (initialResponse.statusCode == 200) {
      print('Successfully saved certificates without redirect');
      try {
        final result = jsonDecode(initialResponse.body);
        return result['success'] == true;
      } catch (e) {
        print('Error parsing JSON from direct response: $e');
        return initialResponse.body.contains('success') || 
               initialResponse.body.contains('saved');
      }
    } 
    // Any other status code is treated as an error
    else {
      throw Exception('Failed to save certificates: ${initialResponse.statusCode}, Body: ${initialResponse.body.substring(0, min(100, initialResponse.body.length))}...');
    }
  } catch (e) {
    print('Error saving certificates: $e');
    return false;
  }
}

// Helper function to get minimum of two numbers (for string truncation)
int min(int a, int b) {
  return a < b ? a : b;
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