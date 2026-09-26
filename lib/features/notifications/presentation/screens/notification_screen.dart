import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/gs_app_bar.dart';
import '../../domain/models/app_notification.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final notifications = service.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GSAppBar(
        title: 'Notifications',
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => service.markAllAsRead(),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const _EmptyNotifications()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    return _NotificationTile(
                      notification: notifications[index],
                      onTap: () => service.markAsRead(notifications[index].id),
                      onDelete: () =>
                          service.deleteNotification(notifications[index].id),
                    );
                  },
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(notification.type).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: AppTextStyles.bodySmall.copyWith(
                color: notification.isRead
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _relativeTime(notification.createdAt),
              style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return 'Earlier';
  }

  IconData _getTypeIcon(NotificationType type) {
    return switch (type) {
      NotificationType.treatment => Icons.medication_rounded,
      NotificationType.scan => Icons.qr_code_scanner_rounded,
      NotificationType.community => Icons.people_rounded,
      NotificationType.system => Icons.notifications_rounded,
    };
  }

  Color _getTypeColor(NotificationType type) {
    return switch (type) {
      NotificationType.treatment => AppColors.warning,
      NotificationType.scan => AppColors.primary,
      NotificationType.community => AppColors.info,
      NotificationType.system => AppColors.textSecondary,
    };
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: AppColors.border),
          SizedBox(height: 16),
          Text('No notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('We\'ll notify you about your plant\'s health.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
