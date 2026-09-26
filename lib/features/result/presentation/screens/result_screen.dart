// lib/features/result/presentation/screens/result_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../domain/models/disease_result_model.dart';
import '../../../scan/domain/models/scan_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ResultScreen
// ─────────────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  final DiseaseResult? result;
  final ScanResult? scanResult;

  const ResultScreen({super.key, this.result, this.scanResult});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late DiseaseResult _result;

  late AnimationController _heroController;
  late AnimationController _contentController;
  late Animation<double> _heroFade;
  late Animation<double> _contentSlide;
  @override
  void initState() {
    super.initState();
    _setupResult();
    _setupAnimations();
  }

  void _setupResult() {
    if (widget.scanResult != null) {
      final s = widget.scanResult!;
      _result = DiseaseResult(
        cropName: s.cropName,
        diseaseName: s.diseaseName,
        diseaseImageUrl: '',
        confidenceScore: s.confidenceScore,
        severity: s.severity,
        status: s.status,
        description: s.description,
        treatments: _treatmentsFor(s.status),
        preventionTips: _preventionFor(s.status),
        details: _detailsFor(s.status),
      );

      // Schedule follow-up notification
      if (s.status.toLowerCase() != 'healthy') {
        appNotifications.scheduleTreatmentReminder(
          diseaseName: s.diseaseName,
          scanId: 'latest', // Simplified for demo
          delay: const Duration(hours: 48),
        );
      }
    } else {
      _result = widget.result ?? _fallbackResult();
    }
  }

  void _setupAnimations() {
    _heroController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _contentSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _shareResult() {
    final summary = [
      'Crop: ${_result.cropName}',
      'Result: ${_result.diseaseName}',
      'Status: ${_result.status}',
      'Severity: ${_result.severity}',
      'Confidence: ${_result.confidencePercentage}',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Result copied. Share it anywhere.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _statusColor(String status, [String? severity]) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return AppColors.success;
      case 'moderate':
      case 'medium':
      case 'warning':
        return AppColors.warning;
      default:
        if (severity?.toLowerCase() == 'moderate' ||
            severity?.toLowerCase() == 'medium') {
          return AppColors.warning;
        }
        return AppColors.error;
    }
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'moderate':
        return const Color(0xFFF97316);
      case 'low':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  // ── Image builder — File path → placeholder ────────────────────────────────

  /// Resolves the leaf image widget.
  /// Uses [File] from [ScanResult.imagePath]; falls back to placeholder.
  Widget _leafImage(
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final sr = widget.scanResult;
    if (sr != null && sr.hasImage) {
      final file = File(sr.imagePath);
      if (file.existsSync()) {
        final mediaQuery = MediaQuery.of(context);
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: (mediaQuery.size.width * mediaQuery.devicePixelRatio)
              .round()
              .clamp(1, 1600),
          cacheHeight: (mediaQuery.size.height * mediaQuery.devicePixelRatio)
              .round()
              .clamp(1, 2400),
          frameBuilder: (ctx, child, frame, sync) {
            if (sync) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (ctx, error, stackTrace) => _placeholder(width, height),
        );
      }
    }
    return _placeholder(width, height);
  }

  Widget _placeholder(double? width, double? height) => Container(
        width: width,
        height: height,
        color: _statusColor(_result.status, _result.severity)
            .withValues(alpha: 0.10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 48,
                color: _statusColor(_result.status, _result.severity)),
            const SizedBox(height: 8),
            const Text('Image unavailable',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      extendBodyBehindAppBar: true,
      appBar: _TransparentAppBar(
        onShare: _shareResult,
        onBack: () => context.pop(),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // 1 ── Hero image ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _heroFade,
              child: _buildHero(),
            ),
          ),

          // 2 ── Low confidence warning ──────────────────────────────────────
          if (_result.isLowConfidence)
            SliverToBoxAdapter(child: _LowConfidenceBanner()),

          // 3 ── Content (slide-up) ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (_, child) => Opacity(
                opacity: _contentController.value,
                child: Transform.translate(
                    offset: Offset(0, _contentSlide.value), child: child),
              ),
              child: Column(
                children: [
                  _ConfidenceSummaryCard(result: _result),
                  const SizedBox(height: 12),
                  _buildStatusCards(),
                  const SizedBox(height: 12),
                  _buildDescriptionCard(),
                  const SizedBox(height: 12),
                  _buildKeyInfoCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          // ── Actual captured image (Hero animates from ScanScreen) ─────────
          Positioned.fill(
            child: Hero(
              tag: AppRoutes.scanImageHeroTag,
              child: _leafImage(width: double.infinity, height: 360),
            ),
          ),

          // Top vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.50),
                    Colors.black.withOpacity(0.80),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Disease info
          Positioned(
            left: 20,
            right: 88,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  _HeroBadge(
                    label: _result.status.toUpperCase(),
                    color: _statusColor(_result.status),
                    icon: _result.status.toLowerCase() == 'diseased'
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 8),
                  _HeroBadge(
                    label: _result.severity.toUpperCase(),
                    color: _severityColor(_result.severity),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(
                  _result.diseaseName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.agriculture_rounded,
                      color: Colors.white60, size: 14),
                  const SizedBox(width: 5),
                  Text(_result.cropName,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
          ),

          // Confidence arc
          Positioned(
            right: 20,
            bottom: 20,
            child: _ConfidenceArc(value: _result.confidenceScore),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: _StatusCard(
            label: 'Status',
            value: _result.status.toUpperCase(),
            icon: _result.status.toLowerCase() == 'diseased'
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            color: _statusColor(_result.status),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusCard(
            label: 'Severity',
            value: _result.severity.toUpperCase(),
            icon: Icons.analytics_outlined,
            color: _severityColor(_result.severity),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusCard(
            label: 'Confidence',
            value: _result.confidencePercentage,
            icon: Icons.verified_rounded,
            color: AppColors.primary,
          ),
        ),
      ]),
    );
  }

  Widget _buildDescriptionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text('About This Disease',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text(_result.description,
              style: AppTextStyles.bodyMedium
                  .copyWith(height: 1.65, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildKeyInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.science_outlined,
                    color: Color(0xFFF97316), size: 18),
              ),
              const SizedBox(width: 10),
              Text('Key Information',
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
          _InfoRow2(
              label: 'Pathogen',
              value: _result.details.pathogen,
              icon: Icons.biotech_outlined),
          _Divider2(),
          _InfoRow2(
              label: 'Temperature',
              value: _result.details.optimalTemperature,
              icon: Icons.thermostat_outlined),
          _Divider2(),
          _InfoRow2(
              label: 'Humidity',
              value: _result.details.humidity,
              icon: Icons.water_drop_outlined),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        // Primary — gradient CTA
        GestureDetector(
          onTap: () => context.push(
            '${AppRoutes.result}/detail',
            extra:
                widget.scanResult, // ← forward same ScanResult with imagePath
          ),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C17C), Color(0xFF00995F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.medical_services_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('View Full Treatment Plan', style: AppTextStyles.buttonText),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary — retake
        GestureDetector(
          onTap: () => context.pushReplacement(AppRoutes.scan),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text('Retake Photo',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.primary)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Result guidance data ───────────────────────────────────────────────────

  List<TreatmentStep> _treatmentsFor(String status) {
    final isHealthy = status.toLowerCase() == 'healthy';
    if (isHealthy) {
      return [
        TreatmentStep(
          step: 1,
          title: 'Continue Monitoring',
          description:
              'Check tomato leaves regularly, especially after rain or humid weather.',
          icon: 'visibility_outlined',
        ),
        TreatmentStep(
          step: 2,
          title: 'Keep Leaves Dry',
          description:
              'Water near the soil level and avoid unnecessary moisture on leaves.',
          icon: 'water_drop_outlined',
        ),
        TreatmentStep(
          step: 3,
          title: 'Maintain Airflow',
          description:
              'Keep proper spacing between tomato plants to reduce humidity buildup.',
          icon: 'air_rounded',
        ),
      ];
    }

    return [
      TreatmentStep(
        step: 1,
        title: 'Remove Infected Leaves',
        description:
            'Prune affected leaves carefully and dispose of them away from healthy tomato plants.',
        icon: 'content_cut_rounded',
      ),
      TreatmentStep(
        step: 2,
        title: 'Reduce Leaf Moisture',
        description:
            'Avoid overhead watering. Late Blight spreads faster in wet and humid conditions.',
        icon: 'water_drop_outlined',
      ),
      TreatmentStep(
        step: 3,
        title: 'Use Recommended Fungicide',
        description:
            'Apply a locally recommended fungicide after consulting an agriculture expert or extension worker.',
        icon: 'medical_services_outlined',
      ),
    ];
  }

  List<PreventionTip> _preventionFor(String status) => [
        PreventionTip(
          title: 'Good Spacing',
          description:
              'Maintain airflow around tomato plants so leaves dry quickly after watering or rain.',
          icon: 'air_rounded',
        ),
        PreventionTip(
          title: 'Clean Field Hygiene',
          description:
              'Remove infected plant debris and disinfect tools after pruning.',
          icon: 'cleaning_services_outlined',
        ),
        PreventionTip(
          title: 'Re-scan Early',
          description:
              'Scan again if water-soaked brown patches, white mold, or stem lesions appear.',
          icon: 'qr_code_scanner_rounded',
        ),
      ];

  DiseaseDetails _detailsFor(String status) {
    final isHealthy = status.toLowerCase() == 'healthy';
    if (isHealthy) {
      return DiseaseDetails(
        overview:
            'No clear Tomato Late Blight pattern was detected in this image. Continue preventive monitoring.',
        pathogen: 'Not detected',
        optimalTemperature: 'Monitor after cool/wet weather',
        humidity: 'Keep foliage dry',
        spreadMechanism: 'N/A',
      );
    }

    return DiseaseDetails(
      overview:
          'Tomato Late Blight can spread quickly in cool, wet, and humid weather and may affect leaves, stems, and fruit.',
      pathogen: 'Phytophthora infestans',
      optimalTemperature: '10°C - 24°C',
      humidity: 'High humidity / wet leaves',
      spreadMechanism: 'Wind, rain splash, infected debris',
    );
  }

  DiseaseResult _fallbackResult() => DiseaseResult(
        cropName: 'Tomato',
        diseaseName: 'Tomato Late Blight',
        diseaseImageUrl: '',
        confidenceScore: 0.86,
        severity: 'high',
        status: 'diseased',
        description:
            'Tomato Late Blight is a serious tomato disease that can damage leaves, stems, and fruits quickly under humid conditions.',
        treatments: _treatmentsFor('diseased'),
        preventionTips: _preventionFor('diseased'),
        details: _detailsFor('diseased'),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TransparentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onShare;
  final VoidCallback onBack;

  const _TransparentAppBar({
    required this.onShare,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: onBack,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24)),
          child: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      title: const Text('Analysis Result',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: onShare,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24)),
            child:
                const Icon(Icons.share_outlined, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _HeroBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3)),
      ]),
    );
  }
}

class _ConfidenceArc extends StatelessWidget {
  final double value;
  const _ConfidenceArc({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24)),
      child: CustomPaint(
        painter: _ArcPainter(value: value),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${(value * 100).toInt()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1)),
            const Text('AI',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  const _ArcPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const start = -math.pi / 2;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi,
        false,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi * value,
        false,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value;
}

class _ConfidenceSummaryCard extends StatelessWidget {
  final DiseaseResult result;
  const _ConfidenceSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        const Icon(Icons.analytics_outlined,
            color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Diagnosis Overview',
              style: AppTextStyles.titleSmall
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.primary, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(result.confidencePercentage,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatusCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.2)),
      ]),
    );
  }
}

class _LowConfidenceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Lower confidence detected. Consider re-scanning with better lighting.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.warning, height: 1.45),
          ),
        ),
      ]),
    );
  }
}

class _InfoRow2 extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow2(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}

class _Divider2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(color: AppColors.border.withOpacity(0.5), height: 1));
}
