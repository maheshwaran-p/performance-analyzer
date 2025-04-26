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
          
          // Check if there are any valid certificates
          final validResults = results.where((result) => result['isOriginal'] == true).toList();
          final hasValidCertificates = validResults.isNotEmpty;
          
          // Calculate average score only for valid certificates
          final averageScore = hasValidCertificates 
              ? (validResults.map((r) => r['score'] as int).reduce((a, b) => a + b) / validResults.length).round()
              : 0;
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Only show overall score card if there are valid certificates
              if (hasValidCertificates)
                _buildOverallScoreCard(context, averageScore),
              
              if (hasValidCertificates)
                const SizedBox(height: 20),
              
              // Certificate details title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Certificate Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Certificate result cards
              ...results.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                
                return _buildResultCard(context, result, index);
              }).toList(),
              
              const SizedBox(height: 20),
              
              // Submit button only if there are valid certificates
              if (hasValidCertificates)
                _buildSubmitButton(context, provider),
              
              if (!hasValidCertificates)
                _buildNoValidCertificatesMessage(context),
                
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
  
  Widget _buildNoValidCertificatesMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'No Valid Certificates Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'None of your uploaded certificates passed our validation checks. Please check the recommendations below or try uploading different certificates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverallScoreCard(BuildContext context, int averageScore) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insights, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Your Valid Certificates Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getScoreColor(averageScore).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getScoreMessage(averageScore),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _getScoreColor(averageScore),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton(BuildContext context, CertificateProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Submit Your Valid Certificates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Click the button below to save your valid certificates to your profile. Only certificates marked as valid will be submitted.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
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
                      // Save the valid certificates
                      final success = await provider.saveValidCertificates(userEmail);
                      
                      // Dismiss loading indicator
                      if (context.mounted) Navigator.pop(context);
                      
                      // Show success message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success 
                                ? 'Certificates successfully submitted!' 
                                : 'No valid certificates to submit',
                            ),
                            backgroundColor: success ? Colors.green : Colors.orange,
                          ),
                        );
                        
                        if (success) {
                          // Navigate back to home screen
                          Navigator.pop(context);
                        }
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
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_upload),
                    SizedBox(width: 10),
                    Text(
                      'Submit Valid Certificates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultCard(BuildContext context, dynamic result, int index) {
    final isOriginal = result['isOriginal'] as bool? ?? false;
    final certificateType = result['certificateType'] as String? ?? 'Unknown';
    final score = isOriginal ? (result['score'] as int?) ?? 0 : 0;
    final authReason = result['authenticationReason'] as String? ?? 'No information available';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOriginal ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOriginal ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      isOriginal ? Icons.check_circle : Icons.cancel,
                      color: isOriginal ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['filename'] ?? 'Unknown Filename',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOriginal ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOriginal ? 'Valid' : 'Invalid',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOriginal ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Certificate Type',
                    certificateType,
                    Icons.category,
                  ),
                ),
                if (isOriginal)
                  Expanded(
                    child: _buildInfoItem(
                      'Score',
                      '$score',
                      Icons.star,
                      valueColor: _getScoreColor(score),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authentication Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authReason,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 85) return Colors.green.shade900;
    if (score >= 70) return Colors.green.shade500;
    if (score >= 50) return Colors.green.shade400;
    return Colors.red.shade700;
  }
  
  String _getScoreMessage(int score) {
    if (score >= 85) return 'Excellent! Your certificates are highly valuable.';
    if (score >= 70) return 'Good job! Your certificates have solid value.';
    if (score >= 50) return 'Decent start. Consider our recommendations to improve.';
    return 'There\'s room for improvement. Follow our recommendations.';
  }
}