import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/scan_history_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../history/domain/models/scan_history_record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanHistoryService>().loadScans();
    });
  }

  Future<void> _refresh() async {
    await context.read<ScanHistoryService>().loadScans();
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        context.watch<AuthSessionService>().displayName.split(' ').first;
    final historyService = context.watch<ScanHistoryService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              _HomeHeader(firstName: firstName),
              const SizedBox(height: 24),
              const _HeroScanCard(),
              const SizedBox(height: 24),
              _LastScanSection(
                scans: historyService.scans,
                isLoading: historyService.isLoading,
              ),
              const SizedBox(height: 24),
              const _GuidanceSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String firstName;

  const _HomeHeader({required this.firstName});

  @override
  Widget build(BuildContext context) {
    context.watch<AuthSessionService>();
    final notifications = context.watch<NotificationService>();

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(AppRoutes.profile),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Grow healthy tomatoes today',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () => context.push(AppRoutes.notifications),
              icon: const Icon(Icons.notifications_none_rounded, size: 26),
              color: AppColors.textPrimary,
            ),
            if (notifications.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${notifications.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroScanCard extends StatelessWidget {
  const _HeroScanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detect Tomato Late Blight Early',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan a clear tomato leaf image and get result, confidence, treatment, and prevention guidance.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.scan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text(
                    'Start Scan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Image.asset(
            'assets/icons/tomato.png',
            width: 86,
            height: 86,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text('Quick Guidance', style: AppTextStyles.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: const [
              _GuidanceCard(
                icon: Icons.water_drop_rounded,
                title: 'Watering',
                subtitle: 'Avoid wet leaves to prevent blight.',
                color: AppColors.info,
              ),
              SizedBox(width: 16),
              _GuidanceCard(
                icon: Icons.eco_rounded,
                title: 'Leaf Care',
                subtitle: 'Prune bottom leaves for airflow.',
                color: AppColors.primary,
              ),
              SizedBox(width: 16),
              _GuidanceCard(
                icon: Icons.health_and_safety_rounded,
                title: 'Treatment',
                subtitle: 'Apply fungicides early if detected.',
                color: AppColors.warning,
              ),
              SizedBox(width: 16),
              _GuidanceCard(
                icon: Icons.shield_rounded,
                title: 'Prevention',
                subtitle: 'Use disease-resistant varieties.',
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _GuidanceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.34), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LastScanSection extends StatelessWidget {
  final List<ScanHistoryRecord> scans;
  final bool isLoading;

  const _LastScanSection({required this.scans, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final last = scans.isEmpty ? null : scans.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Scan', style: AppTextStyles.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(AppRoutes.history),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const _Card(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (last == null)
          _Card(
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No saved scans yet. Start your first tomato leaf diagnosis.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          _LastScanTile(record: last),
      ],
    );
  }
}

class _LastScanTile extends StatelessWidget {
  final ScanHistoryRecord record;

  const _LastScanTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.isHealthy ? AppColors.success : AppColors.error;
    return _Card(
      onTap: () => context.push(AppRoutes.result, extra: record.toScanResult()),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _HistoryImage(path: record.imagePath),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.diseaseName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(record.confidenceScore * 100).toInt()}% confidence • ${record.cropName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryImage extends StatelessWidget {
  final String path;

  const _HistoryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (path.isNotEmpty && file.existsSync()) {
      final cacheSize = (64 * MediaQuery.devicePixelRatioOf(context)).round();
      return Image.file(
        file,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
      );
    }
    return Container(
      width: 64,
      height: 64,
      color: AppColors.primarySurface,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppColors.primary),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
