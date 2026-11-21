import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:blightscan/core/services/cloudinary_service.dart';
import 'package:blightscan/core/data_sources/scan_history_remote_data_source.dart';
import 'package:blightscan/features/history/domain/models/scan_history_record.dart';

void main() {
  test('uploads multipart image and unsigned preset, returns secure URL',
      () async {
    final dir = await Directory.systemTemp.createTemp('cloudinary_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = await File('${dir.path}/leaf.jpg').writeAsBytes([1, 2, 3]);
    final service = CloudinaryService(client: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, CloudinaryService.uploadEndpoint);
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('jloxzriq'));
      expect(request.body, contains('name="file"'));
      return http.Response(
          '{"secure_url":"https://res.cloudinary.com/test/leaf.jpg"}', 200);
    }));
    expect(await service.uploadImage(file),
        'https://res.cloudinary.com/test/leaf.jpg');
    for (final response in [
      http.Response('{}', 400),
      http.Response('invalid', 200),
      http.Response('{"secure_url":"http://unsafe/image"}', 200)
    ]) {
      expect(
          await CloudinaryService(client: MockClient((_) async => response))
              .uploadImage(file),
          isNull);
    }
    expect(await service.uploadImage(File('${dir.path}/missing')), isNull);
  });

  test('history commit includes required fields and server timestamp',
      () async {
    final source =
        ScanHistoryRemoteDataSource(client: MockClient((request) async {
      expect(request.url.path, endsWith('documents:commit'));
      expect(request.headers['authorization'], 'Bearer token');
      final write = jsonDecode(request.body)['writes'][0];
      expect(write['update']['name'], endsWith('/scan_history/scan1'));
      final fields = write['update']['fields'];
      expect(fields['userId']['stringValue'], 'user1');
      expect(fields['imageUrl']['stringValue'], 'https://example.com/leaf.jpg');
      expect(fields['prediction']['stringValue'], 'Late Blight');
      expect(fields['confidence']['doubleValue'], 0.9);
      expect(fields['treatmentPlan']['arrayValue']['values'], [
        {'stringValue': 'Saved plan'}
      ]);
      expect(write['updateTransforms'], [
        {'fieldPath': 'timestamp', 'setToServerValue': 'REQUEST_TIME'}
      ]);
      return http.Response('{}', 200);
    }));
    await source.saveScan(
        ScanHistoryRecord(
            id: 'scan1',
            userId: 'user1',
            imagePath: '',
            imageUrl: 'https://example.com/leaf.jpg',
            diseaseName: 'Late Blight',
            cropName: 'Tomato',
            confidenceScore: 0.9,
            severity: 'high',
            status: 'diseased',
            description: '',
            createdAt: DateTime(2026),
            treatmentPlan: ['Saved plan']),
        'token');
  });

  test('history query is restricted to the current user', () async {
    final source =
        ScanHistoryRemoteDataSource(client: MockClient((request) async {
      if (request.method == 'POST') {
        final query = jsonDecode(request.body)['structuredQuery'];
        expect(query['from'][0]['collectionId'], 'scan_history');
        expect(query['where']['fieldFilter']['value']['stringValue'], 'user1');
        return http.Response('[]', 200);
      }
      return http.Response('{}', 200);
    }));
    expect(await source.fetchScans('user1', 'token'), isEmpty);
  });
}
