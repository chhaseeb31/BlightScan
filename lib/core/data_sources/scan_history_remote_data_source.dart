import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/history/domain/models/scan_history_record.dart';
import '../config/app_config.dart';

class ScanHistoryRemoteDataSource {
  final http.Client client;
  ScanHistoryRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();
  String get _root =>
      'projects/${AppConfig.firebaseProjectId}/databases/(default)/documents';
  Uri _uri(String suffix) =>
      Uri.https('firestore.googleapis.com', '/v1/$_root$suffix');
  Map<String, String> _headers(String token) =>
      {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw StateError('Firestore request failed (${response.statusCode}).');
  }

  Future<List<ScanHistoryRecord>> fetchScans(
      String userId, String token) async {
    final response = await client
        .post(_uri(':runQuery'),
            headers: _headers(token),
            body: jsonEncode({
              'structuredQuery': {
                'from': [
                  {'collectionId': 'scan_history'}
                ],
                'where': {
                  'fieldFilter': {
                    'field': {'fieldPath': 'userId'},
                    'op': 'EQUAL',
                    'value': {'stringValue': userId}
                  }
                },
              }
            }))
        .timeout(const Duration(seconds: 20));
    _check(response);
    final rows = jsonDecode(response.body) as List;
    final records = rows
        .whereType<Map<String, dynamic>>()
        .where((row) => row['document'] != null)
        .map((row) => _record(row['document'] as Map<String, dynamic>, userId))
        .toList();
    // Previous app versions stored records in the user's scans subcollection.
    String? page;
    do {
      final legacy = await client
          .get(
              _uri('/users/$userId/scans').replace(queryParameters: {
                'pageSize': '100',
                if (page != null) 'pageToken': page
              }),
              headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (legacy.statusCode == 404) break;
      _check(legacy);
      final data = jsonDecode(legacy.body) as Map<String, dynamic>;
      final ids = records.map((r) => r.id).toSet();
      records.addAll((data['documents'] as List? ?? [])
          .map((d) => _record(d as Map<String, dynamic>, userId))
          .where((r) => !ids.contains(r.id)));
      page = data['nextPageToken'] as String?;
    } while (page != null && page.isNotEmpty);
    return records..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveScan(ScanHistoryRecord record, String token) async {
    if (record.imageUrl.isEmpty) throw StateError('Image upload is required.');
    final response = await client
        .post(_uri(':commit'),
            headers: _headers(token),
            body: jsonEncode({
              'writes': [
                {
                  'update': {
                    'name': '$_root/scan_history/${record.id}',
                    'fields': {
                      'userId': {'stringValue': record.userId},
                      'imageUrl': {'stringValue': record.imageUrl},
                      'prediction': {'stringValue': record.diseaseName},
                      'confidence': {'doubleValue': record.confidenceScore},
                      'treatmentPlan': {
                        'arrayValue': {
                          'values': record.treatmentPlan
                              .map((s) => {'stringValue': s})
                              .toList()
                        }
                      },
                      'cropName': {'stringValue': record.cropName},
                      'severity': {'stringValue': record.severity},
                      'status': {'stringValue': record.status},
                      'description': {'stringValue': record.description},
                    }
                  },
                  // Same server transform as FieldValue.serverTimestamp() in the SDK.
                  'updateTransforms': [
                    {
                      'fieldPath': 'timestamp',
                      'setToServerValue': 'REQUEST_TIME'
                    }
                  ],
                }
              ]
            }))
        .timeout(const Duration(seconds: 20));
    _check(response);
  }

  Future<void> deleteScan(String userId, String scanId, String token) async {
    for (final path in [
      '/scan_history/$scanId',
      '/users/$userId/scans/$scanId'
    ]) {
      final response = await client
          .delete(_uri(path), headers: _headers(token))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 404) _check(response);
    }
  }

  ScanHistoryRecord _record(Map<String, dynamic> doc, String uid) {
    final f = doc['fields'] as Map<String, dynamic>? ?? {};
    String text(String key, [String fallback = '']) =>
        f[key]?['stringValue'] as String? ?? fallback;
    final prediction = text('prediction', text('diseaseName', 'Unknown'));
    final confidence = f['confidence'] ?? f['confidenceScore'];
    return ScanHistoryRecord(
        id: (doc['name'] as String).split('/').last,
        userId: text('userId', uid),
        imagePath: text('imagePath'),
        imageUrl: text('imageUrl'),
        diseaseName: prediction,
        cropName: text('cropName', 'Tomato'),
        confidenceScore: double.tryParse(
                '${confidence?['doubleValue'] ?? confidence?['integerValue'] ?? 0}') ??
            0,
        severity: text('severity', 'unknown'),
        status: text(
            'status',
            prediction.toLowerCase().contains('healthy')
                ? 'healthy'
                : 'diseased'),
        description: text('description'),
        treatmentPlan:
            (f['treatmentPlan']?['arrayValue']?['values'] as List? ?? [])
                .map((v) => v['stringValue'] as String)
                .toList(),
        createdAt: DateTime.tryParse((f['timestamp'] ??
                        f['createdAt'])?['timestampValue'] as String? ??
                    '')
                ?.toLocal() ??
            DateTime.now());
  }
}
