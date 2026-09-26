/// Disease analysis result model
class DiseaseResult {
  final String cropName;
  final String diseaseName;
  final String diseaseImageUrl;
  final double confidenceScore; // 0.0 - 1.0
  final String severity; // low, moderate, high
  final String status; // healthy, diseased
  final String description;
  final List<TreatmentStep> treatments;
  final List<PreventionTip> preventionTips;
  final DiseaseDetails details;

  DiseaseResult({
    required this.cropName,
    required this.diseaseName,
    required this.diseaseImageUrl,
    required this.confidenceScore,
    required this.severity,
    required this.status,
    required this.description,
    required this.treatments,
    required this.preventionTips,
    required this.details,
  });

  // Severity color mapping
  String get severityColor {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'error';
      case 'moderate':
        return 'warning';
      case 'low':
        return 'success';
      default:
        return 'info';
    }
  }

  // Confidence display
  String get confidencePercentage => '${(confidenceScore * 100).toInt()}%';

  // Is confidence low (< 70%)
  bool get isLowConfidence => confidenceScore < 0.7;

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      cropName: json['cropName'] as String? ?? 'Unknown',
      diseaseName: json['diseaseName'] as String? ?? 'Unknown Disease',
      diseaseImageUrl: json['diseaseImageUrl'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.85,
      severity: json['severity'] as String? ?? 'moderate',
      status: json['status'] as String? ?? 'diseased',
      description: json['description'] as String? ?? '',
      treatments: (json['treatments'] as List?)
              ?.map((e) => TreatmentStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preventionTips: (json['preventionTips'] as List?)
              ?.map((e) => PreventionTip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      details: json['details'] != null
          ? DiseaseDetails.fromJson(json['details'] as Map<String, dynamic>)
          : DiseaseDetails.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cropName': cropName,
        'diseaseName': diseaseName,
        'diseaseImageUrl': diseaseImageUrl,
        'confidenceScore': confidenceScore,
        'severity': severity,
        'status': status,
        'description': description,
        'treatments': treatments.map((e) => e.toJson()).toList(),
        'preventionTips': preventionTips.map((e) => e.toJson()).toList(),
        'details': details.toJson(),
      };
}

class TreatmentStep {
  final int step;
  final String title;
  final String description;
  final String icon; // icon name or emoji
  final bool isCompleted;

  TreatmentStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
  });

  factory TreatmentStep.fromJson(Map<String, dynamic> json) {
    return TreatmentStep(
      step: json['step'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'local_florist',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'description': description,
        'icon': icon,
        'isCompleted': isCompleted,
      };
}

class PreventionTip {
  final String title;
  final String description;
  final String icon;

  PreventionTip({
    required this.title,
    required this.description,
    required this.icon,
  });

  factory PreventionTip.fromJson(Map<String, dynamic> json) {
    return PreventionTip(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'shield_outlined',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'icon': icon,
      };
}

class DiseaseDetails {
  final String overview;
  final String pathogen;
  final String optimalTemperature;
  final String humidity;
  final String spreadMechanism;

  DiseaseDetails({
    required this.overview,
    required this.pathogen,
    required this.optimalTemperature,
    required this.humidity,
    required this.spreadMechanism,
  });

  factory DiseaseDetails.fromJson(Map<String, dynamic> json) {
    return DiseaseDetails(
      overview: json['overview'] as String? ?? '',
      pathogen: json['pathogen'] as String? ?? '',
      optimalTemperature: json['optimalTemperature'] as String? ?? '',
      humidity: json['humidity'] as String? ?? '',
      spreadMechanism: json['spreadMechanism'] as String? ?? '',
    );
  }

  factory DiseaseDetails.empty() => DiseaseDetails(
        overview: '',
        pathogen: '',
        optimalTemperature: '',
        humidity: '',
        spreadMechanism: '',
      );

  Map<String, dynamic> toJson() => {
        'overview': overview,
        'pathogen': pathogen,
        'optimalTemperature': optimalTemperature,
        'humidity': humidity,
        'spreadMechanism': spreadMechanism,
      };
}
