import 'dart:io';

class Certificate {
  final String filename;
  final String fileType;
  final File file;
  bool? isOriginal;
  String? authenticationReason;

  Certificate({
    required this.filename,
    required this.fileType,
    required this.file,
    this.isOriginal,
    this.authenticationReason,
  });

  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png'].contains(fileType.toLowerCase());
}