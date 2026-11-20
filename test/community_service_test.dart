import 'package:blightscan/core/services/auth_session_service.dart';
import 'package:blightscan/core/services/firebase_identity_service.dart';
import 'package:blightscan/core/services/firebase_user_profile_service.dart';
import 'package:blightscan/features/community/data/services/community_service.dart';
import 'package:blightscan/features/community/domain/models/community_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('photo uploads authenticate the REST session and use an owner folder',
      () async {
    final session = AuthSessionService(
      identityService: _TestIdentityService(),
      userProfileService: _TestProfileService(),
    );
    await session.signIn(
        email: 'user@example.com', password: 'password', rememberMe: false);
    final temp = await Directory.systemTemp.createTemp('blightscan-upload-');
    addTearDown(() => temp.delete(recursive: true));
    final file = await File('${temp.path}/leaf.jpg')
        .writeAsBytes([255, 216, 255, 224, 0]);
    late http.Request request;
    final service = CommunityService(
        authSession: session,
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
              jsonEncode({'downloadTokens': 'download-token'}), 200);
        }));
    final url = await service.uploadPostImage(file);
    expect(request.headers['authorization'], 'Firebase test-token');
    expect(request.url.queryParameters['name'],
        startsWith('community_posts/test-user/'));
    expect(request.headers['x-goog-upload-protocol'], 'multipart');
    expect(url, contains('community_posts%2Ftest-user%2F'));
    expect(url, contains('token=download-token'));
  });

  test('loadPosts surfaces an auth-required state instead of silently failing',
      () async {
    final service = CommunityService(authSession: AuthSessionService());

    await service.loadPosts();

    expect(service.loadError, 'Please sign in to view community posts.');
    expect(service.posts, isEmpty);
    expect(service.isLoading, isFalse);
  });

  test('toggleLike targets community_posts with Firebase bearer auth',
      () async {
    var isAuthorized = false;
    final session = AuthSessionService(
      identityService: _TestIdentityService(),
      userProfileService: _TestProfileService(),
    );
    await session.signIn(
      email: 'user@example.com',
      password: 'password',
      rememberMe: false,
    );

    late http.Request request;
    final service = CommunityService(
      authSession: session,
      client: MockClient((incoming) async {
        request = incoming;
        isAuthorized = incoming.headers['authorization'] == 'Bearer test-token';
        return http.Response('{}', 200);
      }),
    );

    await service.toggleLike(
      CommunityPost(
        id: 'post-1',
        authorId: 'another-user',
        authorName: 'Other User',
        caption: 'Test post',
        imageUrls: [],
        createdAt: DateTime.utc(2026),
        likedBy: [],
      ),
    );

    expect(request.url.path, endsWith('/documents/community_posts/post-1'));
    expect(request.url.queryParametersAll['updateMask.fieldPaths'],
        ['likedBy', 'likeCount']);
    expect(request.url.queryParameters['currentDocument.exists'], 'true');
    expect(isAuthorized, isTrue);
  });
}

class _TestIdentityService extends FirebaseIdentityService {
  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async =>
      const AuthUser(
        uid: 'test-user',
        email: 'user@example.com',
        displayName: 'Test User',
        idToken: 'test-token',
        refreshToken: 'test-refresh-token',
      );
}

class _TestProfileService extends FirebaseUserProfileService {
  @override
  Future<bool> ensureUserProfile(AuthUser user) async => true;
}
