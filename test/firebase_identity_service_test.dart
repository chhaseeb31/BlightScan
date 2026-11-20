import 'dart:convert';

import 'package:blightscan/core/services/firebase_identity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('retains signup UID and refreshes token after partial display update',
      () async {
    final requests = <dynamic>[];
    final service = FirebaseIdentityService(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('accounts:signUp')) {
          return httpResponse({
            'localId': 'firebase-uid',
            'email': 'plant@example.com',
            'idToken': 'signup-id-token',
            'refreshToken': 'signup-refresh-token',
          });
        }
        if (request.url.path.endsWith('accounts:update')) {
          return httpResponse({'displayName': 'Plant User'});
        }
        return httpResponse({
          'user_id': 'firebase-uid',
          'id_token': 'fresh-id-token',
          'refresh_token': 'rotated-refresh-token',
        });
      }),
    );

    final user = await service.createAccount(
      displayName: 'Plant User',
      email: 'plant@example.com',
      password: 'test-password',
    );

    expect(requests, hasLength(3));
    expect(user.uid, 'firebase-uid');
    expect(user.idToken, 'fresh-id-token');
  });

  test('refreshes an ID token when signup response omits it', () async {
    final requests = <dynamic>[];
    final service = FirebaseIdentityService(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('accounts:signUp')) {
          return httpResponse({
            'localId': 'firebase-uid',
            'email': 'plant@example.com',
            'refreshToken': 'signup-refresh-token',
          });
        }
        return httpResponse({
          'user_id': 'firebase-uid',
          'id_token': 'fresh-id-token',
          'refresh_token': 'rotated-refresh-token',
        });
      }),
    );

    final user = await service.createAccount(
      displayName: '',
      email: 'plant@example.com',
      password: 'test-password',
    );

    expect(requests, hasLength(2));
    expect(user.uid, 'firebase-uid');
    expect(user.idToken, 'fresh-id-token');
    expect(user.refreshToken, 'rotated-refresh-token');
  });
}

http.Response httpResponse(Map<String, dynamic> body) =>
    http.Response(jsonEncode(body), 200);
