import 'package:flutter/material.dart';
import 'package:blightscan/core/constants/app_colors.dart';
import 'package:blightscan/core/widgets/gs_logo.dart';
import 'package:blightscan/core/widgets/gs_cards.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24,
          top: 16,
          right: 24,
          bottom: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const GSLogo(size: 64),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'BlightScan',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSectionTitle(context, 'Our Mission'),
            GSCard(
              child: Text(
                'BlightScan is an AI-powered Flutter mobile application focused on early Tomato Late Blight detection from tomato leaf images. It helps users check a leaf image, understand the result, and follow basic treatment and prevention guidance.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Key Features'),
            GSCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFeatureRow(
                      context,
                      Icons.bolt_rounded,
                      'Instant AI Detection',
                      'Analyze tomato leaf images and classify Healthy or Late Blight affected.'),
                  const Divider(height: 32),
                  _buildFeatureRow(
                      context,
                      Icons.analytics_outlined,
                      'Confidence & Status',
                      'View confidence, status, and severity in a simple result screen.'),
                  const Divider(height: 32),
                  _buildFeatureRow(context, Icons.medical_services_outlined,
                      'Treatment Guidance', 'See symptoms, basic actions, and prevention tips for Tomato Late Blight.'),
                  const Divider(height: 32),
                  _buildFeatureRow(
                      context,
                      Icons.history_rounded,
                      'Scan History',
                      'Review previous tomato leaf diagnoses.'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Final Year Design Project',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 BlightScan Team',
                    style: TextStyle(
                      color: AppColors.textTertiary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildFeatureRow(
      BuildContext context, IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
