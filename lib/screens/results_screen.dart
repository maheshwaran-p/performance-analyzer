import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/certificate_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/recommendation_card.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Consumer<CertificateProvider>(
        builder: (context, provider, child) {
          final results = provider.results;
          final averageScore = provider.averageScore;
          
          // Check if there are any valid certificates
          final hasValidCertificates = results.any((result) => result['isOriginal'] == true);
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Overall score card
              _buildOverallScoreCard(context, averageScore),
              
              const SizedBox(height: 20),
              
              // Certificate details title
              Text(
                'Certificate Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              // Certificate result cards
              ...results.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                
                // If certificate type is unknown, ensure score is 0
                if (result['certificateType'] == 'Unknown' || result['certificateType'] == 'Unidentified') {
                  result['score'] = 0;
                }
                
                return _buildResultCard(context, result, index);
              }).toList(),
              
              const SizedBox(height: 20),
              
              // Submit button only if there are valid certificates
              if (hasValidCertificates)
                _buildSubmitButton(context, provider),
              
              const SizedBox(height: 20),
              
              // Recommendations
              RecommendationCard(
                recommendations: provider.allRecommendations,
              ),
              
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildOverallScoreCard(BuildContext context, int averageScore) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Your Overall Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: averageScore / 100,
                      strokeWidth: 15,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(averageScore),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$averageScore',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(averageScore),
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getScoreMessage(averageScore),
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton(BuildContext context, CertificateProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            try {
              // Get current user email
              final userEmail = Provider.of<UserProvider>(context, listen: false).currentUser?.email;
              
              if (userEmail != null) {
                // Only submit certificates that are valid
                final validCertificates = provider.certificates.where((cert) => cert.isOriginal == true).toList();
                
                // Save the valid certificates
                await provider.saveValidCertificates(userEmail);
                
                // Dismiss loading indicator
                if (context.mounted) Navigator.pop(context);
                
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certificates successfully submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Navigate back to home screen
                  Navigator.pop(context);
                }
              } else {
                // Dismiss loading indicator
                if (context.mounted) Navigator.pop(context);
                
                // Show error message if user not logged in
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to submit certificates'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } catch (e) {
              // Dismiss loading indicator
              if (context.mounted) Navigator.pop(context);
              
              // Show error message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error submitting certificates: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Submit Valid Certificates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultCard(BuildContext context, dynamic result, int index) {
    // Ensure score is 0 if certificate type is Unknown
    final score = (result['certificateType'] == 'Unknown' || 
                    result['certificateType'] == 'Unidentified') 
                    ? 0 
                    : result['score'];
                    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['filename'] ?? 'Unknown Filename',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Certificate Type:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result['certificateType'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Score display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Score:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(score),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Validation status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: result['isOriginal'] 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    result['isOriginal'] 
                      ? Icons.check_circle 
                      : Icons.cancel,
                    color: result['isOriginal'] 
                      ? Colors.green 
                      : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result['isOriginal'] ? 'Valid' : 'Invalid',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: result['isOriginal'] 
                        ? Colors.green 
                        : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Authentication Reason
            Text(
              result['authenticationReason'] ?? 'No additional information',
              style: TextStyle(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
  
  String _getScoreMessage(int score) {
    if (score >= 85) return 'Excellent! Your certificates are highly valuable.';
    if (score >= 70) return 'Good job! Your certificates have solid value.';
    if (score >= 50) return 'Decent start. Consider our recommendations to improve.';
    return 'There\'s room for improvement. Follow our recommendations.';
  }
}