import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/domain/models/app_notification.dart';
import 'auth_session_service.dart';

final NotificationService appNotifications =
    NotificationService(authSession: authSession);

class NotificationService extends ChangeNotifier {
  NotificationService({required this.authSession}) {
    authSession.addListener(_onAuthChanged);
  }

  String? _loadedUid;
  void _onAuthChanged() {
    final uid = authSession.currentUser?.uid;
    if (_loadedUid == uid) return;
    _loadedUid = uid;
    _notifications = [];
    loadNotifications();
  }

  @override
  void dispose() {
    authSession.removeListener(_onAuthChanged);
    super.dispose();
  }

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
      _notifications = [];
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw);
        _notifications =
            list.map((item) => AppNotification.fromLocalJson(item)).toList();
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _notifications.removeWhere((item) => item.id.startsWith('demo_'));
    } catch (e) {
      debugPrint('[NotificationService] Load failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    final uid = authSession.currentUser?.uid;
    Future.delayed(delay, () {
      if (uid != authSession.currentUser?.uid) return;
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
