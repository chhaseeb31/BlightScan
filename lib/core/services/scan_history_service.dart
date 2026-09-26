import 'package:flutter/foundation.dart';
import '../../features/history/domain/models/scan_history_record.dart';
import '../../features/scan/domain/models/scan_result.dart';
import '../repositories/scan_history_repository.dart';
import 'auth_session_service.dart';

/// Manage scan history state and coordinate between UI and Repository.
class ScanHistoryService extends ChangeNotifier {
  final AuthSessionService authSession;
  final ScanHistoryRepository repository;

  final List<ScanHistoryRecord> _scans = [];
  bool _isLoading = false;
  String? _lastLoadedUid;
  Future<void>? _loadFuture;

  ScanHistoryService({
    required this.authSession,
    required this.repository,
  });

  List<ScanHistoryRecord> get scans => List.unmodifiable(_scans);
  bool get isLoading => _isLoading;

  String get _currentUid => authSession.currentUser?.uid ?? 'guest';
  String? get _token => authSession.currentUser?.idToken;

  Future<void> loadScans() {
    final activeLoad = _loadFuture;
    if (activeLoad != null) return activeLoad;

    final future = _loadScans();
    _loadFuture = future.whenComplete(() => _loadFuture = null);
    return _loadFuture!;
  }

  Future<void> _loadScans() async {
    final uid = _currentUid;
    if (_lastLoadedUid != null && _lastLoadedUid != uid) {
      _scans.clear();
      notifyListeners();
    }
    _lastLoadedUid = uid;

    _setLoading(true);
    try {
      final records = await repository.getScans(userId: uid, token: _token);
      _scans.clear();
      _scans.addAll(records);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<ScanHistoryRecord> saveScan(ScanResult result) async {
    final now = DateTime.now();
    final record = ScanHistoryRecord(
      id: 'scan_${now.microsecondsSinceEpoch}',
      userId: _currentUid,
      imagePath: result.imagePath,
      diseaseName: result.diseaseName,
      cropName: result.cropName,
      confidenceScore: result.confidenceScore,
      severity: result.severity,
      status: result.status,
      description: result.description,
      createdAt: now,
    );

    // Optimistic update
    _scans.insert(0, record);
    notifyListeners();

    await repository.saveScan(
        userId: _currentUid, record: record, token: _token);
    return record;
  }

  Future<void> deleteScan(String scanId) async {
    _scans.removeWhere((e) => e.id == scanId);
    notifyListeners();
    await repository.deleteScan(
        userId: _currentUid, scanId: scanId, token: _token);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void clearInMemory() {
    _scans.clear();
    _lastLoadedUid = null;
    notifyListeners();
  }
}
