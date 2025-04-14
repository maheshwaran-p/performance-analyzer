import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/certificate_provider.dart';
import '../screens/results_screen.dart';
import 'certificate_item.dart';

class UploadWidget extends StatelessWidget {
  const UploadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CertificateProvider>(
      builder: (context, provider, child) {
        return provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildUploadArea(context, provider),
                  ),
                  if (provider.certificates.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildFileListHeader(context, provider),
                    ),
                  if (provider.certificates.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final certificate = provider.certificates[index];
                          return CertificateItem(
                            certificate: certificate,
                            onRemove: () => provider.removeCertificate(index),
                          );
                        },
                        childCount: provider.certificates.length,
                      ),
                    ),
                  if (provider.certificates.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildAnalyzeButton(context, provider),
                    ),
                ],
              );
      },
    );
  }

  Widget _buildUploadArea(BuildContext context, CertificateProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          InkWell(
            onTap: () => provider.pickFiles(),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(65),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                size: 60,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tap to upload certificates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            'Supported formats: PDF, JPG, JPEG, PNG',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListHeader(BuildContext context, CertificateProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Selected Files (${provider.certificates.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextButton.icon(
            onPressed: () => provider.clearCertificates(),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton(BuildContext context, CertificateProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await provider.analyzeCertificates();
            if (provider.results.isNotEmpty && context.mounted) {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const ResultsScreen(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Analyze Certificates',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}