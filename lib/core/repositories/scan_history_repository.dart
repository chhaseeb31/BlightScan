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
        await localDataSource.saveScans(userId, remoteScans);
        return remoteScans;
      } catch (e) {
        // Fallback to local on remote error
        return localDataSource.getScans(userId);
      }
    }
    
    return localDataSource.getScans(userId);
  }

  Future<void> saveScan({
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
      } catch (e) {
        // Log or handle background sync later
      }
    }
  }

  Future<void> deleteScan({
    required String userId,
    required String scanId,
    String? token,
  }) async {
    await localDataSource.deleteScan(userId, scanId);
    if (token != null && token.isNotEmpty && userId != 'guest') {
      try {
        await remoteDataSource.deleteScan(userId, scanId, token);
      } catch (e) {
        // Handle error
      }
    }
  }
}
