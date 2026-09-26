import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/history/domain/models/scan_history_record.dart';

class ScanHistoryLocalDataSource {
  static const String _baseKey = 'scan_history';

  String _userKey(String userId) => '$_baseKey.$userId';

  Future<List<ScanHistoryRecord>> getScans(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey(userId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ScanHistoryRecord.fromLocalJson)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveScan(String userId, ScanHistoryRecord record) async {
    final scans = await getScans(userId);
    scans.removeWhere((e) => e.id == record.id);
    scans.insert(0, record);
    await saveScans(userId, scans.take(100).toList());
  }

  Future<void> saveScans(String userId, List<ScanHistoryRecord> scans) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = scans.map((e) => e.toLocalJson()).toList();
    await prefs.setString(_userKey(userId), jsonEncode(payload));
  }

  Future<void> deleteScan(String userId, String scanId) async {
    final scans = await getScans(userId);
    scans.removeWhere((e) => e.id == scanId);
    await saveScans(userId, scans);
  }
}
