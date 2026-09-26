import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/history/domain/models/scan_history_record.dart';
import '../config/app_config.dart';

class ScanHistoryRemoteDataSource {
  final http.Client client;

  ScanHistoryRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  Uri _documentsUri(String path, [Map<String, String>? query]) {
    return Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${AppConfig.firebaseProjectId}/databases/(default)/documents/$path',
      query,
    );
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<List<ScanHistoryRecord>> fetchScans(String userId, String token) async {
    final response = await client
        .get(
          _documentsUri('users/$userId/scans', {'pageSize': '100'}),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) return [];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Firestore load failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = body['documents'] as List<dynamic>? ?? [];
    return docs
        .whereType<Map<String, dynamic>>()
        .map((doc) => _recordFromDocument(doc, userId))
        .where((e) => e.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveScan(ScanHistoryRecord record, String token) async {
    await client
        .post(
          _documentsUri('users/${record.userId}/scans', {'documentId': record.id}),
          headers: _headers(token),
          body: jsonEncode({'fields': _fieldsFromRecord(record)}),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<void> deleteScan(String userId, String scanId, String token) async {
    await client
        .delete(
          _documentsUri('users/$userId/scans/$scanId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 20));
  }

  Map<String, dynamic> _fieldsFromRecord(ScanHistoryRecord record) {
    return {
      'id': {'stringValue': record.id},
      'userId': {'stringValue': record.userId},
      'imagePath': {'stringValue': record.imagePath},
      'diseaseName': {'stringValue': record.diseaseName},
      'cropName': {'stringValue': record.cropName},
      'confidenceScore': {'doubleValue': record.confidenceScore},
      'severity': {'stringValue': record.severity},
      'status': {'stringValue': record.status},
      'description': {'stringValue': record.description},
      'createdAt': {
        'timestampValue': record.createdAt.toUtc().toIso8601String()
      },
    };
  }

  ScanHistoryRecord _recordFromDocument(Map<String, dynamic> doc, String userId) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String? ?? '';
    final docId = name.split('/').last;

    return ScanHistoryRecord(
      id: _stringField(fields, 'id', fallback: docId),
      userId: _stringField(fields, 'userId', fallback: userId),
      imagePath: _stringField(fields, 'imagePath'),
      diseaseName: _stringField(fields, 'diseaseName', fallback: 'Unknown'),
      cropName: _stringField(fields, 'cropName', fallback: 'Tomato'),
      confidenceScore: _doubleField(fields, 'confidenceScore'),
      severity: _stringField(fields, 'severity', fallback: 'unknown'),
      status: _stringField(fields, 'status', fallback: 'unknown'),
      description: _stringField(fields, 'description'),
      createdAt: _dateField(fields, 'createdAt'),
    );
  }

  String _stringField(Map<String, dynamic> fields, String key,
      {String fallback = ''}) {
    final value = fields[key];
    if (value is Map<String, dynamic>) {
      return value['stringValue'] as String? ?? fallback;
    }
    return fallback;
  }

  double _doubleField(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is Map<String, dynamic>) {
      final doubleValue = value['doubleValue'];
      if (doubleValue is num) return doubleValue.toDouble();
      final integerValue = value['integerValue'];
      if (integerValue is String) return double.tryParse(integerValue) ?? 0;
    }
    return 0;
  }

  DateTime _dateField(Map<String, dynamic> fields, String key) {
    final value = fields[key];
    if (value is Map<String, dynamic>) {
      final timestamp = value['timestampValue'];
      if (timestamp is String) {
        return DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
      }
    }
    return DateTime.now();
  }
}
