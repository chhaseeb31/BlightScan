import '../../features/history/domain/models/scan_history_record.dart';
import '../data_sources/scan_history_local_data_source.dart';
import '../data_sources/scan_history_remote_data_source.dart';

class ScanHistoryRepository {
  final ScanHistoryLocalDataSource localDataSource;
  final ScanHistoryRemoteDataSource remoteDataSource;

  ScanHistoryRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<List<ScanHistoryRecord>> getScans({
    required String userId,
    String? token,
  }) async {
    // Try remote first, then sync local
    if (token != null && token.isNotEmpty && userId != 'guest') {
      try {
        final remoteScans = await remoteDataSource.fetchScans(userId, token);
        final pending =
            (await localDataSource.getScans(userId)).where((r) => !r.synced);
        final combined = <String, ScanHistoryRecord>{
          for (final r in remoteScans) r.id: r,
          for (final r in pending) r.id: r
        }.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await localDataSource.saveScans(userId, combined);
        return combined;
      } catch (e) {
        // Fallback to local on remote error
        return localDataSource.getScans(userId);
      }
    }

    return localDataSource.getScans(userId);
  }

  Future<bool> saveScan({
    required String userId,
    required ScanHistoryRecord record,
    String? token,
  }) async {
    // Save local first for instant UI response
    await localDataSource.saveScan(userId, record);

    // Then try remote if possible
    if (token != null && token.isNotEmpty && userId != 'guest') {
      try {
        await remoteDataSource.saveScan(record, token);
        await localDataSource.saveScan(
            userId,
            ScanHistoryRecord.fromLocalJson(
                {...record.toLocalJson(), 'synced': true}));
        return true;
      } catch (e) {
        // Log or handle background sync later
      }
    }
    return false;
  }

  Future<void> deleteScan({
    required String userId,
    required String scanId,
    String? token,
  }) async {
    if (token != null && token.isNotEmpty && userId != 'guest') {
      await remoteDataSource.deleteScan(userId, scanId, token);
    } else {
      throw StateError('Connect and sign in to delete this scan.');
    }
    await localDataSource.deleteScan(userId, scanId);
  }
}
