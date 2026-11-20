import 'package:blightscan/core/services/auth_session_service.dart';
import 'package:blightscan/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a new account has no fabricated treatment reminders', () async {
    SharedPreferences.setMockInitialValues({});
    final service = NotificationService(authSession: AuthSessionService());
    await service.initialize();
    expect(service.notifications, isEmpty);
    expect(service.unreadCount, 0);
    service.dispose();
  });
}
