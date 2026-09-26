import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/domain/models/app_notification.dart';
import 'auth_session_service.dart';

final NotificationService appNotifications =
    NotificationService(authSession: authSession);

class NotificationService extends ChangeNotifier {
  NotificationService({required this.authSession});

  final AuthSessionService authSession;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String get _localKey =>
      'notifications.${authSession.currentUser?.uid ?? 'guest'}';

  Future<void> initialize() async {
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        _notifications =
            list.map((item) => AppNotification.fromLocalJson(item)).toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      if (_notifications.isEmpty) {
        _notifications = _demoNotifications();
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('[NotificationService] Load failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AppNotification> _demoNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'demo_treatment_reminder',
        title: 'Treatment follow-up',
        message: 'Treatment follow-up is due today.',
        createdAt: now.subtract(const Duration(hours: 1)),
        type: NotificationType.treatment,
      ),
      AppNotification(
        id: 'demo_plant_check',
        title: 'Plant check',
        message: 'Check the affected leaves for changes.',
        createdAt: now.subtract(const Duration(days: 1)),
        type: NotificationType.scan,
        isRead: true,
      ),
      AppNotification(
        id: 'demo_follow_up_scan',
        title: 'Follow-up scan',
        message: 'Consider performing a follow-up scan.',
        createdAt: now.subtract(const Duration(days: 3)),
        type: NotificationType.system,
        isRead: true,
      ),
    ];
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedId,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      createdAt: DateTime.now(),
      type: type,
      relatedId: relatedId,
    );

    _notifications.insert(0, notification);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          jsonEncode(_notifications.map((n) => n.toLocalJson()).toList());
      await prefs.setString(_localKey, raw);
    } catch (e) {
      debugPrint('[NotificationService] Save failed: $e');
    }
  }

  /// Schedules a treatment reminder (simulated for now by adding a notification after delay)
  void scheduleTreatmentReminder({
    required String diseaseName,
    required String scanId,
    required Duration delay,
  }) {
    Future.delayed(delay, () {
      addNotification(
        title: 'Treatment Follow-up',
        message:
            'It\'s time to inspect your tomato plant for $diseaseName recovery.',
        type: NotificationType.treatment,
        relatedId: scanId,
      );
    });
  }
}
