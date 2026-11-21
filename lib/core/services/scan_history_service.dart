import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'cloudinary_service.dart';
import 'package:flutter/foundation.dart';
import '../../features/history/domain/models/scan_history_record.dart';
import '../../features/scan/domain/models/scan_result.dart';
import '../repositories/scan_history_repository.dart';
import 'auth_session_service.dart';

/// Manage scan history state and coordinate between UI and Repository.
class ScanHistoryService extends ChangeNotifier {
  final AuthSessionService authSession;
  final ScanHistoryRepository repository;

  final CloudinaryService _cloudinary = CloudinaryService();
  String? lastSaveError;
  final List<ScanHistoryRecord> _scans = [];
  bool _isLoading = false;
  String? _lastLoadedUid;
  Future<void>? _loadFuture;

  ScanHistoryService({
    required this.authSession,
    required this.repository,
  }) {
    authSession.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_lastLoadedUid != _currentUid) clearInMemory();
  }

  @override
  void dispose() {
    authSession.removeListener(_onAuthChanged);
    super.dispose();
  }

  List<ScanHistoryRecord> get scans => List.unmodifiable(_scans);
  bool get isLoading => _isLoading;

  String get _currentUid => authSession.currentUser?.uid ?? 'guest';

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
      final pending = await repository.localDataSource.getScans(uid);
      for (final record in pending.where((r) => !r.synced)) {
        if (uid != _currentUid) return;
        await _sync(record);
      }
      final records = await repository.getScans(
          userId: uid, token: await authSession.getValidIdToken());
      if (uid != _currentUid) return;
      _scans.clear();
      _scans.addAll(records);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<ScanHistoryRecord> saveScan(ScanResult result,
      {List<String> treatmentPlan = const []}) async {
    lastSaveError = null;
    final now = DateTime.now();
    final uid = _currentUid;
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory('${directory.path}/scan_images/$uid');
    await imageDirectory.create(recursive: true);
    final savedImage = await File(result.imagePath)
        .copy('${imageDirectory.path}/scan_${now.microsecondsSinceEpoch}.jpg');
    final record = ScanHistoryRecord(
      synced: false,
      treatmentPlan: treatmentPlan,
      id: 'scan_${now.microsecondsSinceEpoch}',
      userId: uid,
      imagePath: savedImage.path,
      diseaseName: result.diseaseName,
      cropName: result.cropName,
      confidenceScore: result.confidenceScore,
      severity: result.severity,
      status: result.status,
      description: result.description,
      createdAt: now,
    );

    // Optimistic update
    if (uid == _currentUid) {
      _scans.insert(0, record);
      notifyListeners();
    }

    await repository.localDataSource.saveScan(record.userId, record);
    final synced = await _sync(record);
    if (record.userId == _currentUid) {
      final index = _scans.indexWhere((r) => r.id == record.id);
      if (index >= 0) _scans[index] = synced;
      notifyListeners();
    }
    return synced;
  }

  Future<ScanHistoryRecord> _sync(ScanHistoryRecord record) async {
    final uid = record.userId;
    final token = await authSession.getValidIdToken();
    if (token == null || uid != _currentUid) {
      lastSaveError =
          'Scan saved locally. Sign in and refresh History to sync.';
      return record;
    }
    final url = record.imageUrl.isNotEmpty
        ? record.imageUrl
        : await _cloudinary.uploadImage(File(record.imagePath));
    if (url == null) {
      lastSaveError =
          'Scan saved on this device. Image upload failed; pull to refresh History to retry.';
      return record;
    }
    final uploaded = ScanHistoryRecord.fromLocalJson(
        {...record.toLocalJson(), 'imageUrl': url});
    await repository.localDataSource.saveScan(uid, uploaded);
    if (uid != _currentUid) return uploaded;
    final success =
        await repository.saveScan(userId: uid, record: uploaded, token: token);
    if (!success) {
      lastSaveError =
          'Scan saved on this device. Cloud sync failed; refresh History to retry.';
    }
    return ScanHistoryRecord.fromLocalJson(
        {...uploaded.toLocalJson(), 'synced': success});
  }

  Future<void> deleteScan(String scanId) async {
    final uid = _currentUid;
    await repository.deleteScan(
        userId: uid,
        scanId: scanId,
        token: await authSession.getValidIdToken());
    if (uid != _currentUid) return;
    _scans.removeWhere((e) => e.id == scanId);
    notifyListeners();
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
