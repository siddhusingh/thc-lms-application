class CertificateModel {
  const CertificateModel({
    required this.id,
    required this.title,
    this.courseTitle,
    this.issuedAt,
    this.fileUrl,
  });

  final String id;
  final String title;
  final String? courseTitle;
  final DateTime? issuedAt;
  final String? fileUrl;

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      title: '${json['title'] ?? json['certificate_no'] ?? 'Certificate'}',
      courseTitle:
          json['course_title']?.toString() ?? json['course']?.toString(),
      issuedAt: DateTime.tryParse(json['issued_at']?.toString() ?? ''),
      fileUrl:
          json['file_url']?.toString() ??
          json['download_url']?.toString() ??
          json['url']?.toString(),
    );
  }
}
