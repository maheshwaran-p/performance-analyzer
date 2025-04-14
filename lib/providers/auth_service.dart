// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class CertificateAuthenticationService {
//   final String openAiApiKey;

//   CertificateAuthenticationService(this.openAiApiKey);

//   Future<Map<String, dynamic>> authenticateCertificate(File file) async {
//     try {
//       // Convert file to base64
//       final bytes = await file.readAsBytes();
//       final base64Image = base64Encode(bytes);

//       // Prepare API request
//       final response = await http.post(
//         Uri.parse('https://api.openai.com/v1/chat/completions'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $openAiApiKey'
//         },
//         body: jsonEncode({
//           'model': 'gpt-4-vision-preview',
//           'messages': [
//             {
//               'role': 'user',
//               'content': [
//                 {
//                   'type': 'text',
//                   'text': 'Analyze this certificate. Is it an original, authentic document? '
//                       'Look for signs of forgery, unusual formatting, or inconsistencies. '
//                       'Provide a detailed assessment of its authenticity. '
//                       'Your response should include a boolean "isOriginal" and a reason.'
//                 },
//                 {
//                   'type': 'image_url',
//                   'image_url': {
//                     'url': 'data:image/jpeg;base64,$base64Image'
//                   }
//                 }
//               ]
//             }
//           ],
//           'max_tokens': 300
//         }),
//       );

//       // Parse response
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         final content = jsonResponse['choices'][0]['message']['content'];
        
//         // Basic parsing of authentication result
//         final isOriginal = content.toLowerCase().contains('authentic') || 
//                           content.toLowerCase().contains('original');
        
//         return {
//           'isOriginal': isOriginal,
//           'reason': content
//         };
//       } else {
//         throw Exception('Failed to authenticate certificate');
//       }
//     } catch (e) {
//       return {
//         'isOriginal': false,
//         'reason': 'Authentication failed: ${e.toString()}'
//       };
//     }
//   }
// }