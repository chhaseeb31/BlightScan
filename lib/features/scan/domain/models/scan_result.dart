class ScanResult {
  final String imagePath;
  final String diseaseName;
  final String cropName;
  final double confidenceScore;
  final String severity;
  final String status;
  final String description;

  const ScanResult({
    required this.imagePath,
    required this.diseaseName,
    required this.cropName,
    required this.confidenceScore,
    required this.severity,
    required this.status,
    required this.description,
  });

  bool get hasImage => imagePath.trim().isNotEmpty;

  ScanResult copyWith({
    String? imagePath,
    String? diseaseName,
    String? cropName,
    double? confidenceScore,
    String? severity,
    String? status,
    String? description,
  }) {
    return ScanResult(
      imagePath: imagePath ?? this.imagePath,
      diseaseName: diseaseName ?? this.diseaseName,
      cropName: cropName ?? this.cropName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      imagePath: json['imagePath'] as String? ?? '',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown',
      cropName: json['cropName'] as String? ?? 'Unknown',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'moderate',
      status: json['status'] as String? ?? 'diseased',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'diseaseName': diseaseName,
    'cropName': cropName,
    'confidenceScore': confidenceScore,
    'severity': severity,
    'status': status,
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult &&
          runtimeType == other.runtimeType &&
          imagePath == other.imagePath &&
          diseaseName == other.diseaseName &&
          cropName == other.cropName &&
          confidenceScore == other.confidenceScore &&
          severity == other.severity &&
          status == other.status &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
    imagePath,
    diseaseName,
    cropName,
    confidenceScore,
    severity,
    status,
    description,
  );
}
