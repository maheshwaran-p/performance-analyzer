class CertificateResult {
  final String type;
  final int score;
  final bool isOriginal;
  final List<String> recommendations;
  final String filename;
  
  CertificateResult({
    required this.type,
    required this.score,
    required this.isOriginal,
    required this.recommendations,
    required this.filename,
  });
  
  factory CertificateResult.fromJson(Map<String, dynamic> json, String filename) {
    return CertificateResult(
      type: json['type'] ?? 'Unknown',
      score: json['score'] ?? 0,
      isOriginal: json['isOriginal'] ?? false,
      recommendations: List<String>.from(json['recommendations'] ?? []),
      filename: filename,
    );
  }
}