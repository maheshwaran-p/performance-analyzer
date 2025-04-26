import 'package:flutter/material.dart';

class AllCertificatesScreen extends StatelessWidget {
  final List<dynamic> certificates;

  const AllCertificatesScreen({
    Key? key,
    required this.certificates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Certificates'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: certificates.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final cert = certificates[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Icon(
                    Icons.verified_user,
                    color: Colors.green.shade700,
                    size: 30,
                  ),
                ),
              ),
              title: Text(
                cert['CertificateName']?.toString() ??
                    cert['filename']?.toString() ??
                    'Certificate ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Score: ${cert['Score'] ?? cert['score'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (cert['certificateType'] != null || cert['CertificateType'] != null)
                    Row(
                      children: [
                        Icon(Icons.category, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cert['certificateType'] ?? cert['CertificateType'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (cert['fileURL'] != null)
                    Row(
                      children: [
                        Icon(Icons.link, color: Colors.purple, size: 16),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            // Implement opening the certificate
                            // You can use url_launcher package
                            // or navigate to a detail view
                          },
                          child: const Text(
                            'View Certificate',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
