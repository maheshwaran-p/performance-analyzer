import 'package:flutter/material.dart';
import 'package:performance_analzer2/models/certificate.dart';
import 'package:performance_analzer2/providers/certificate_provider.dart';


class CertificateItem extends StatelessWidget {
final Certificate certificate;
  final VoidCallback onRemove;

  
  const CertificateItem({
    super.key,
    required this.certificate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _getIconColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(),
            color: _getIconColor(),
            size: 24,
          ),
        ),
        title: Text(
          certificate.filename,
          style: const TextStyle(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          certificate.fileType.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: onRemove,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
  
  IconData _getFileIcon() {
    if (certificate.isPdf) {
      return Icons.picture_as_pdf;
    } else if (certificate.isImage) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }
  
  Color _getIconColor() {
    if (certificate.isPdf) {
      return Colors.red;
    } else if (certificate.isImage) {
      return Colors.blue;
    }
    return Colors.amber;
  }
}