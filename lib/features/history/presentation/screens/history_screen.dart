import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/scan_history_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/gs_app_bar.dart';
import '../../../../core/widgets/gs_input_field.dart';
import '../../domain/models/scan_history_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanHistoryService>().loadScans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await context.read<ScanHistoryService>().loadScans();
  }

  Future<void> _delete(ScanHistoryRecord record) async {
    await context.read<ScanHistoryService>().deleteScan(record.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ScanHistoryService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GSAppBar(title: 'Scan History'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: GSSearchBar(
              hint: 'Search by result or date...',
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (service.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query = _searchController.text.trim().toLowerCase();
                final records = service.scans.where((item) {
                  if (query.isEmpty) return true;
                  return item.diseaseName.toLowerCase().contains(query) ||
                      item.status.toLowerCase().contains(query) ||
                      item.cropName.toLowerCase().contains(query);
                }).toList();

                if (records.isEmpty) {
                  return _EmptyState(
                      onStart: () => context.push(AppRoutes.scan));
                }

                final grouped = _groupByDate(records);
                final rows = _buildRows(grouped);
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, index) => rows[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<ScanHistoryRecord>> _groupByDate(
    List<ScanHistoryRecord> items,
  ) {
    final map = <DateTime, List<ScanHistoryRecord>>{};
    for (final item in items) {
      final key = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  List<Widget> _buildRows(Map<DateTime, List<ScanHistoryRecord>> grouped) {
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final rows = <Widget>[];
    for (final date in keys) {
      rows.add(_DateHeader(label: _formatDateLabel(date)));
      for (final item in grouped[date]!) {
        rows.add(_HistoryTile(
          key: ValueKey('history-${item.id}'),
          item: item,
          onDelete: () => _delete(item),
        ));
      }
    }
    rows.add(const SizedBox(height: AppSpacing.massive));
    return rows;
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[month - 1];
  }
}

class _DateHeader extends StatelessWidget {
  final String label;

  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScanHistoryRecord item;
  final VoidCallback onDelete;

  const _HistoryTile({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status, item.severity);

    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete scan?'),
            content: const Text('This scan will be removed from history.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return shouldDelete ?? false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                context.push(AppRoutes.result, extra: item.toScanResult()),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: _HistoryImage(
                      path: item.imagePath,
                      statusColor: statusColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.diseaseName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _StatusChip(
                              label: item.status,
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(item.confidenceScore * 100).toInt()}% confidence • ${item.cropName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(item.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.iconDefault, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, String severity) {
    if (status.toLowerCase() == 'healthy') return AppColors.success;
    if (severity.toLowerCase() == 'moderate' ||
        status.toLowerCase() == 'moderate' ||
        status.toLowerCase() == 'warning') {
      return AppColors.warning;
    }
    return AppColors.error;
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _HistoryImage extends StatelessWidget {
  final String path;
  final Color statusColor;

  const _HistoryImage({required this.path, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (path.isNotEmpty && file.existsSync()) {
      final cacheSize = (72 * MediaQuery.devicePixelRatioOf(context)).round();
      return Image.file(
        file,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
      );
    }
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: statusColor,
          size: 28,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.document_scanner_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No scan history yet',
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Scan a tomato leaf to save your first diagnosis.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 190,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Start Scan', style: AppTextStyles.buttonText),
              ),
            )
          ],
        ),
      ),
    );
  }
}
