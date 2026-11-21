import 'dart:convert';

import 'package:blightscan/core/services/firebase_identity_service.dart';
import 'package:blightscan/core/services/firebase_user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const user = AuthUser(
    uid: 'firebase-uid',
    email: 'plant@example.com',
    displayName: 'Plant User',
    idToken: 'firebase-id-token',
    refreshToken: 'refresh-token',
  );

  test('profile picture patch preserves other profile fields and reads URL',
      () async {
    final service =
        FirebaseUserProfileService(client: MockClient((request) async {
      expect(request.url.path, endsWith('/users/firebase-uid'));
      if (request.method == 'PATCH') {
        expect(
            request.url.queryParameters['updateMask.fieldPaths'], 'photoUrl');
        expect(jsonDecode(request.body)['fields'].keys.toList(), ['photoUrl']);
        return http.Response('{}', 200);
      }
      return http.Response(
          '{"fields":{"photoUrl":{"stringValue":"https://example.com/avatar.jpg"}}}',
          200);
    }));
    await service.updatePhotoUrl(user, 'https://example.com/avatar.jpg');
    expect(await service.fetchPhotoUrl(user), 'https://example.com/avatar.jpg');
    service.dispose();
  });

  test('creates and verifies a missing user profile at the canonical UID path',
      () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (requests.length == 1) {
        return http.Response('{"error":{"status":"NOT_FOUND"}}', 404);
      }
      if (requests.length == 2) {
        return http.Response('{}', 200);
      }
      return http.Response(
        jsonEncode({
          'fields': {
            'uid': {'stringValue': user.uid},
          },
        }),
        200,
      );
    });
    final service = FirebaseUserProfileService(client: client);

    expect(await service.ensureUserProfile(user), isTrue);
    expect(requests, hasLength(3));
    expect(requests[0].url.path, endsWith('/documents/users/${user.uid}'));
    expect(requests[1].method, 'PATCH');
    expect(requests[1].url.path, endsWith('/documents/users/${user.uid}'));
    expect(requests[1].headers['authorization'], 'Bearer ${user.idToken}');
    final write = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(write['fields']['uid']['stringValue'], user.uid);
    expect(
      requests[1].url.queryParametersAll['updateMask.fieldPaths'],
      contains('uid'),
    );
    expect(requests[2].url.path, endsWith('/documents/users/${user.uid}'));
  });

  test('updates only required fields on an existing profile', () async {
    late http.Request writeRequest;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
            '{"fields":{"uid":{"stringValue":"firebase-uid"}}}', 200);
      }
      writeRequest = request;
      return http.Response('{}', 200);
    });
    final service = FirebaseUserProfileService(client: client);

    expect(await service.ensureUserProfile(user), isTrue);
    final fields =
        writeRequest.url.queryParametersAll['updateMask.fieldPaths'] as List;
    expect(fields, contains('updatedAt'));
    expect(fields, isNot(contains('createdAt')));
    expect(fields, isNot(contains('scanHistory')));
  });

  test('rejects empty credentials instead of skipping provisioning', () async {
    final service = FirebaseUserProfileService(
      client: MockClient((_) async => http.Response('', 500)),
    );

    await expectLater(
      service.ensureUserProfile(user.copyWith(idToken: '')),
      throwsA(isA<ProfileProvisioningException>()),
    );
  });

  test('preserves Firestore error code and message', () async {
    final service = FirebaseUserProfileService(
      client: MockClient((_) async => http.Response(
            '{"error":{"status":"PERMISSION_DENIED","message":"denied"}}',
            403,
          )),
    );

    await expectLater(
      service.ensureUserProfile(user),
      throwsA(
        isA<FirestoreRestException>()
            .having((error) => error.code, 'code', 'PERMISSION_DENIED')
            .having((error) => error.message, 'message', contains('denied')),
      ),
    );
  });
}
