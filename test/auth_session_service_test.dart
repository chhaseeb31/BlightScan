import 'package:blightscan/core/services/auth_session_service.dart';
import 'package:blightscan/core/services/firebase_identity_service.dart';
import 'package:blightscan/core/services/firebase_user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testUser = AuthUser(
  uid: 'firebase-uid',
  email: 'plant@example.com',
  displayName: 'Plant User',
  idToken: 'firebase-id-token',
  refreshToken: 'refresh-token',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('refreshes expired tokens once and preserves remember-me choice',
      () async {
    var now = DateTime.utc(2026);
    final identity = _FakeIdentityService();
    final session = AuthSessionService(
      identityService: identity,
      userProfileService: _FakeProfileService((_) async {}),
      now: () => now,
    );
    await session.signIn(
        email: _testUser.email, password: 'password', rememberMe: false);
    expect(await session.getValidIdToken(), _testUser.idToken);
    expect(identity.refreshCalls, 0);
    now = now.add(const Duration(minutes: 55));
    final tokens = await Future.wait(
        [session.getValidIdToken(), session.getValidIdToken()]);
    expect(tokens, ['renewed-token', 'renewed-token']);
    expect(identity.refreshCalls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth.refreshToken'), isNull);
  });

  test('publishes the authenticated session only after profile provisioning',
      () async {
    late AuthSessionService session;
    var sessionWasPublishedDuringProvisioning = false;
    final profileService = _FakeProfileService((_) async {
      sessionWasPublishedDuringProvisioning = session.isSignedIn;
    });
    session = AuthSessionService(
      identityService: _FakeIdentityService(),
      userProfileService: profileService,
    );

    final result = await session.signUp(
      name: _testUser.displayName,
      email: _testUser.email,
      password: 'test-password',
    );

    expect(result.isSuccess, isTrue);
    expect(sessionWasPublishedDuringProvisioning, isFalse);
    expect(profileService.provisionedUser?.uid, _testUser.uid);
    expect(profileService.provisionedUser?.idToken, _testUser.idToken);
    expect(session.currentUser?.uid, _testUser.uid);
  });

  test('allows sign-in retry after signup provisioning fails', () async {
    var provisionAttempts = 0;
    final profileService = _FakeProfileService((_) async {
      provisionAttempts++;
      if (provisionAttempts == 1) {
        throw const FirestoreRestException(
          statusCode: 503,
          code: 'UNAVAILABLE',
          message: 'Firestore temporarily unavailable',
        );
      }
    });
    final identityService = _FakeIdentityService();
    final session = AuthSessionService(
      identityService: identityService,
      userProfileService: profileService,
    );

    final signup = await session.signUp(
      name: _testUser.displayName,
      email: _testUser.email,
      password: 'test-password',
    );
    expect(signup.isSuccess, isFalse);
    expect(session.isSignedIn, isFalse);

    final signIn = await session.signIn(
      email: _testUser.email,
      password: 'test-password',
      rememberMe: false,
    );

    expect(signIn.isSuccess, isTrue);
    expect(session.currentUser?.uid, _testUser.uid);
    expect(identityService.createAccountCalls, 1);
    expect(identityService.signInCalls, 1);
  });
}

class _FakeIdentityService extends FirebaseIdentityService {
  int createAccountCalls = 0;
  int signInCalls = 0;
  int refreshCalls = 0;

  @override
  Future<AuthUser> refreshSession(
      {required String refreshToken,
      String? fallbackUid,
      String? fallbackName,
      String? fallbackEmail}) async {
    refreshCalls++;
    return _testUser.copyWith(idToken: 'renewed-token');
  }

  @override
  Future<AuthUser> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    createAccountCalls++;
    return _testUser;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    return _testUser;
  }
}

class _FakeProfileService extends FirebaseUserProfileService {
  _FakeProfileService(this.onEnsure);

  final Future<void> Function(AuthUser user) onEnsure;
  AuthUser? provisionedUser;

  @override
  Future<bool> ensureUserProfile(AuthUser user) async {
    provisionedUser = user;
    await onEnsure(user);
    return true;
  }
}
