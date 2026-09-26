// lib/features/result/presentation/screens/treatment_plan_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_routes.dart';
import '../../domain/models/disease_result_model.dart';
import '../../../scan/domain/models/scan_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TreatmentPlanScreen
// ─────────────────────────────────────────────────────────────────────────────

class TreatmentPlanScreen extends StatefulWidget {
  final DiseaseResult? result;
  final ScanResult? scanResult;

  const TreatmentPlanScreen({super.key, this.result, this.scanResult});

  @override
  State<TreatmentPlanScreen> createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DiseaseResult _result;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _setupResult();
    _tabController = TabController(length: 3, vsync: this);
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
        preventionTips: _preventionTips(),
        details: _detailsFor(s.status),
      );
    } else {
      _result = widget.result ?? _fallbackResult();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleStepCompletion(int step) {
    setState(() {
      if (_completedSteps.contains(step)) {
        _completedSteps.remove(step);
      } else {
        _completedSteps.add(step);
      }
    });
  }

  // ── Image resolution — same priority as ResultScreen ──────────────────────

  /// Resolves the leaf image widget using captured File path.
  /// Hero tag continues the animation from ResultScreen.
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
          errorBuilder: (context, error, stackTrace) =>
              _placeholder(width, height),
        );
      }
    }
    return _placeholder(width, height);
  }

  Widget _placeholder(double? width, double? height) => Container(
        width: width,
        height: height,
        color: AppColors.backgroundSecondary,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 40, color: AppColors.textTertiary),
            SizedBox(height: 6),
            Text('Image unavailable',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  double get _completionPercent => _result.treatments.isEmpty
      ? 0.0
      : _completedSteps.length / _result.treatments.length;

  void _shareResult() {
    final summary = [
      'Crop: ${_result.cropName}',
      'Result: ${_result.diseaseName}',
      'Status: ${_result.status}',
      'Severity: ${_result.severity}',
      'Progress: ${(_completionPercent * 100).toInt()}% complete',
    ].join('\n');
    Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Treatment plan copied. Share it anywhere.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Column(
        children: [
          _buildHeroSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TreatmentTabContent(
                  treatments: _result.treatments,
                  completedSteps: _completedSteps,
                  onStepToggle: _toggleStepCompletion,
                ),
                _PreventionTabContent(preventionTips: _result.preventionTips),
                _DetailsTabContent(details: _result.details),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  // ── Hero section ───────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // ── Hero continues animation from ResultScreen ──────────────────
          Positioned.fill(
            child: Hero(
              tag: AppRoutes.scanImageHeroTag,
              child: _leafImage(width: double.infinity, height: 220),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.50),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
          ),

          // SafeArea content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom app bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _CircleIconBtn(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          _result.diseaseName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _CircleIconBtn(
                        icon: Icons.share_outlined,
                        onTap: () {
                          _shareResult();
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Progress info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _HeroChip(
                          label:
                              '${_result.status.toUpperCase()} — ${_result.severity.toUpperCase()}',
                          icon: Icons.info_outline_rounded,
                          color: _severityColor(_result.severity),
                        ),
                        const Spacer(),
                        _HeroChip(
                          label:
                              '${_completedSteps.length}/${_result.treatments.length} Done',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _completionPercent,
                          minHeight: 7,
                          backgroundColor: Colors.white.withOpacity(0.20),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(_completionPercent * 100).toInt()}% Treatment Progress',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pill tab bar ───────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(children: [
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Treatment'),
              Tab(text: 'Prevention'),
              Tab(text: 'Details'),
            ],
          ),
        ),
        const SizedBox(height: 2),
      ]),
    );
  }

  // ── Bottom actions ─────────────────────────────────────────────────────────

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        border:
            Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(children: [
        // Secondary — View saved scans
        Expanded(
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.history),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 7),
                  Text('View History',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.primary, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Primary — Re-Scan (gradient)
        Expanded(
          child: GestureDetector(
            onTap: () => context.pushReplacement(AppRoutes.scan),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C17C), Color(0xFF00995F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 7),
                  Text('Re-Scan',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Treatment and prevention data ──────────────────────────────────────────

  List<TreatmentStep> _treatmentsFor(String status) {
    final isHealthy = status.toLowerCase() == 'healthy';
    if (isHealthy) {
      return [
        TreatmentStep(
          step: 1,
          title: 'Keep Monitoring',
          description:
              'Your tomato leaf looks healthy. Continue regular visual checks, especially after rain or humid weather.',
          icon: 'visibility_outlined',
        ),
        TreatmentStep(
          step: 2,
          title: 'Water Safely',
          description:
              'Water near the soil and avoid wetting leaves unnecessarily because wet leaves increase disease risk.',
          icon: 'water_drop_outlined',
        ),
        TreatmentStep(
          step: 3,
          title: 'Maintain Airflow',
          description:
              'Keep good spacing between plants so tomato leaves dry faster after rain or irrigation.',
          icon: 'air_rounded',
        ),
      ];
    }

    return [
      TreatmentStep(
        step: 1,
        title: 'Remove Infected Leaves',
        description:
            'Prune affected tomato leaves and dispose of them away from the field. Do not compost infected material.',
        icon: 'content_cut_rounded',
      ),
      TreatmentStep(
        step: 2,
        title: 'Reduce Moisture',
        description:
            'Stop overhead watering and improve drainage/airflow. Late Blight spreads faster when foliage remains wet.',
        icon: 'water_drop_outlined',
      ),
      TreatmentStep(
        step: 3,
        title: 'Apply Expert-Recommended Fungicide',
        description:
            'Use a locally recommended fungicide and dosage after consulting an agriculture expert or extension worker.',
        icon: 'medical_services_outlined',
      ),
    ];
  }

  List<PreventionTip> _preventionTips() => [
        PreventionTip(
          title: 'Avoid Wet Leaves',
          description:
              'Use soil-level watering where possible and avoid unnecessary leaf wetness.',
          icon: 'water_drop_outlined',
        ),
        PreventionTip(
          title: 'Clean Tools',
          description:
              'Disinfect pruning tools after cutting infected leaves to reduce disease spread.',
          icon: 'cleaning_services_outlined',
        ),
        PreventionTip(
          title: 'Early Re-Scan',
          description:
              'Scan again if new water-soaked brown patches, white mold, or stem lesions appear.',
          icon: 'qr_code_scanner_rounded',
        ),
      ];

  DiseaseDetails _detailsFor(String status) {
    final isHealthy = status.toLowerCase() == 'healthy';
    if (isHealthy) {
      return DiseaseDetails(
        overview:
            'No clear Tomato Late Blight symptoms were detected in this scan. Keep monitoring because conditions can change quickly.',
        pathogen: 'Not detected',
        optimalTemperature: 'Risk increases in cool/wet weather',
        humidity: 'Keep foliage dry',
        spreadMechanism: 'N/A',
      );
    }

    return DiseaseDetails(
      overview:
          'Tomato Late Blight is caused by Phytophthora infestans and can spread rapidly in cool, wet, and humid conditions.',
      pathogen: 'Phytophthora infestans',
      optimalTemperature: '10°C - 24°C',
      humidity: 'High humidity / wet leaves',
      spreadMechanism: 'Wind, rain splash, infected plant debris',
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
            'Tomato Late Blight can spread quickly in humid weather and damage leaves, stems, and fruits if not managed early.',
        treatments: _treatmentsFor('diseased'),
        preventionTips: _preventionTips(),
        details: _detailsFor('diseased'),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Circle icon button (hero area)
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        onPressed: onTap,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero chip
// ─────────────────────────────────────────────────────────────────────────────

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _HeroChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Treatment Tab
// ─────────────────────────────────────────────────────────────────────────────

class _TreatmentTabContent extends StatelessWidget {
  final List<TreatmentStep> treatments;
  final Set<int> completedSteps;
  final Function(int) onStepToggle;

  const _TreatmentTabContent({
    required this.treatments,
    required this.completedSteps,
    required this.onStepToggle,
  });

  @override
  Widget build(BuildContext context) {
    final done = completedSteps.length;
    final total = treatments.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          icon: Icons.medical_services_outlined,
          iconColor: AppColors.primary,
          title: 'Step-by-Step Treatment',
          subtitle: 'Follow these steps to manage the disease effectively.',
          trailing: done == total && total > 0
              ? _CompletedBadge()
              : Text('$done / $total steps',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        ...List.generate(treatments.length, (i) {
          final t = treatments[i];
          return _TreatmentStepCard(
            treatment: t,
            isCompleted: completedSteps.contains(t.step),
            isLast: i == treatments.length - 1,
            onToggle: () => onStepToggle(t.step),
          );
        }),
        if (done == total && total > 0) ...[
          const SizedBox(height: 8),
          _AllDoneCard(),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TreatmentStepCard extends StatelessWidget {
  final TreatmentStep treatment;
  final bool isCompleted;
  final bool isLast;
  final VoidCallback onToggle;

  const _TreatmentStepCard({
    required this.treatment,
    required this.isCompleted,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 44,
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isCompleted ? AppColors.primary : AppColors.border,
                    width: 2),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20, key: ValueKey('check'))
                      : Text('${treatment.step}',
                          key: const ValueKey('num'),
                          style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 12),

        // Card body
        Expanded(
          child: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primarySurface
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.border.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCompleted
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        treatment.title,
                        style: AppTextStyles.titleSmall.copyWith(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textSecondary,
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted ? 'Done ✓' : 'Tap to mark',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    treatment.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCompleted
                          ? AppColors.textSecondary.withOpacity(0.7)
                          : AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00C17C), Color(0xFF00995F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(children: [
        const Icon(Icons.celebration_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('All Steps Completed!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('Great job! Monitor your crop over the next week.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 13),
        const SizedBox(width: 4),
        Text('All done',
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.success, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Prevention Tab
// ─────────────────────────────────────────────────────────────────────────────

class _PreventionTabContent extends StatelessWidget {
  final List<PreventionTip> preventionTips;
  const _PreventionTabContent({required this.preventionTips});

  static const List<Color> _colors = [
    Color(0xFF00C17C),
    Color(0xFF3B82F6),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          icon: Icons.shield_outlined,
          iconColor: Color(0xFF3B82F6),
          title: 'Preventive Measures',
          subtitle: 'Implement these strategies to prevent future outbreaks.',
        ),
        const SizedBox(height: 16),
        ...List.generate(preventionTips.length, (i) {
          final tip = preventionTips[i];
          final color = _colors[i % _colors.length];
          return _PreventionCard(tip: tip, color: color, index: i + 1);
        }),
      ],
    );
  }
}

class _PreventionCard extends StatelessWidget {
  final PreventionTip tip;
  final Color color;
  final int index;
  const _PreventionCard(
      {required this.tip, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetails(context),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.22), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text('$index',
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip.title,
                          style: AppTextStyles.titleSmall
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(tip.description,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary, height: 1.5)),
                    ]),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.10), shape: BoxShape.circle),
                child:
                    Icon(Icons.chevron_right_rounded, color: color, size: 18),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final detail = _detailText(tip.title);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tip.title, style: AppTextStyles.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(detail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _detailText(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('tool')) {
      return 'Clean pruning and cutting tools between plants and after handling affected leaves. Wipe or disinfect the blades, then let them dry before the next cut. This helps reduce mechanical spread of pathogens from one plant to another.';
    }
    if (normalized.contains('scan')) {
      return 'Check tomato leaves regularly, especially after wet or humid weather. Look for new water-soaked patches, expanding brown lesions, white growth on the underside, or stem marks. Scan suspicious leaves early so you can respond before symptoms spread.';
    }
    return 'Avoid unnecessary leaf wetness by watering near the soil where possible. If a leaf shows suspicious spots or lesions, remove it carefully and dispose of it away from healthy plants instead of leaving infected material in the crop area.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Details Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsTabContent extends StatelessWidget {
  final DiseaseDetails details;
  const _DetailsTabContent({required this.details});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeader(
          icon: Icons.document_scanner_outlined,
          iconColor: Color(0xFF8B5CF6),
          title: 'Disease Overview',
          subtitle: null,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Text(details.overview,
              style: AppTextStyles.bodyMedium
                  .copyWith(height: 1.65, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 30),
        const _SectionHeader(
          icon: Icons.science_outlined,
          iconColor: Color(0xFFF97316),
          title: 'Key Information',
          subtitle: null,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 4),
            children: [
              _InfoTile(
                  label: 'Pathogen',
                  value: details.pathogen,
                  icon: Icons.biotech_outlined,
                  color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              _InfoTile(
                  label: 'Temperature',
                  value: details.optimalTemperature,
                  icon: Icons.thermostat_outlined,
                  color: AppColors.error),
              const SizedBox(width: 12),
              _InfoTile(
                  label: 'Humidity',
                  value: details.humidity,
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _InfoTile(
                  label: 'Spread',
                  value: details.spreadMechanism,
                  icon: Icons.air_rounded,
                  color: const Color(0xFFF97316)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      height: 178,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.28), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
            if (trailing != null) trailing!,
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ]),
      ),
    ]);
  }
}
