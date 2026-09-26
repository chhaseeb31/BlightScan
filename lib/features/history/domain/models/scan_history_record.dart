import '../../../scan/domain/models/scan_result.dart';

/// Firestore/local-storage representation of a saved BlightScan diagnosis.
class ScanHistoryRecord {
  final String id;
  final String userId;
  final String imagePath;
  final String diseaseName;
  final String cropName;
  final double confidenceScore;
  final String severity;
  final String status;
  final String description;
  final DateTime createdAt;

  const ScanHistoryRecord({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.diseaseName,
    required this.cropName,
    required this.confidenceScore,
    required this.severity,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  bool get isHealthy => status.toLowerCase() == 'healthy';

  ScanResult toScanResult() {
    return ScanResult(
      imagePath: imagePath,
      diseaseName: diseaseName,
      cropName: cropName,
      confidenceScore: confidenceScore,
      severity: severity,
      status: status,
      description: description,
    );
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'diseaseName': diseaseName,
      'cropName': cropName,
      'confidenceScore': confidenceScore,
      'severity': severity,
      'status': status,
      'description': description,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory ScanHistoryRecord.fromLocalJson(Map<String, dynamic> json) {
    return ScanHistoryRecord(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown',
      cropName: json['cropName'] as String? ?? 'Tomato',
      confidenceScore: _readDouble(json['confidenceScore']),
      severity: json['severity'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
