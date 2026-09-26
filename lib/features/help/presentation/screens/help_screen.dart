import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gs_app_bar.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GSAppBar(
        title: 'Help & Support',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          _buildSearchSection(),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Common Questions'),
          _buildFaqItem(
            'How do I scan a tomato leaf?',
            'Tap the scan button, capture or upload a clear tomato leaf image, and keep the leaf in good light for better analysis.',
          ),
          _buildFaqItem(
            'What disease is supported?',
            'This FYP version is intentionally focused on Tomato Late Blight detection only. Healthy tomato leaf classification is also supported.',
          ),
          _buildFaqItem(
            'Is the diagnosis final medical/agriculture advice?',
            'The result is a decision-support output. For large crop losses, pesticide use, or unclear symptoms, consult a local agricultural expert before taking major action.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Contact Us'),
          _buildContactCard(
            'Email Support',
            'support@blightscan.com',
            Icons.email_outlined,
          ),
          _buildContactCard(
            'Live Chat',
            'Available 9 AM - 6 PM',
            Icons.chat_bubble_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search for help...',
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: AppColors.iconDefault),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.iconDefault),
        ],
      ),
    );
  }
}
