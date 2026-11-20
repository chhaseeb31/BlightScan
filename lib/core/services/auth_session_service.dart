import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_identity_service.dart';
import 'firebase_user_profile_service.dart';

final AuthSessionService authSession = AuthSessionService();

class AuthActionResult {
  final bool isSuccess;
  final String message;

  const AuthActionResult.success([this.message = 'Success']) : isSuccess = true;

  const AuthActionResult.failure(this.message) : isSuccess = false;
}

class AuthSessionService extends ChangeNotifier {
  AuthSessionService({
    FirebaseIdentityService? identityService,
    FirebaseUserProfileService? userProfileService,
    DateTime Function()? now,
  })  : _identityService = identityService ?? FirebaseIdentityService(),
        _now = now ?? DateTime.now,
        _userProfileService =
            userProfileService ?? FirebaseUserProfileService();

  static const String _uidKey = 'auth.uid';
  static const String _emailKey = 'auth.email';
  static const String _displayNameKey = 'auth.displayName';
  static const String _idTokenKey = 'auth.idToken';
  static const String _refreshTokenKey = 'auth.refreshToken';

  final FirebaseIdentityService _identityService;
  final DateTime Function() _now;
  final FirebaseUserProfileService _userProfileService;
  SharedPreferences? _prefs;
  AuthUser? _currentUser;
  bool _isReady = false;
  bool _rememberMe = false;
  DateTime? _tokenAcquiredAt;
  Future<String?>? _refreshFuture;

  // Refresh before Firebase ID tokens expire and share concurrent refresh work.
  // Persist renewed credentials only when the user selected remember me.
  Future<String?> getValidIdToken() async {
    final user = _currentUser;
    if (user == null) return null;
    if (_tokenAcquiredAt != null &&
        _now().difference(_tokenAcquiredAt!) < const Duration(minutes: 50)) {
      return user.idToken;
    }
    return _refreshFuture ??=
        _refreshToken(user).whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _refreshToken(AuthUser user) async {
    try {
      final updated = await _identityService.refreshSession(
        refreshToken: user.refreshToken,
        fallbackUid: user.uid,
        fallbackName: user.displayName,
        fallbackEmail: user.email,
      );
      if (!identical(_currentUser, user)) return null;
      _currentUser = updated;
      _tokenAcquiredAt = _now();
      if (_rememberMe) await _persistUser(updated);
      return updated.idToken;
    } catch (error, stack) {
      _logAuthFailure('token refresh', error, stack);
      return null;
    }
  }

  bool get isReady => _isReady;
  bool get isSignedIn => _currentUser != null;
  AuthUser? get currentUser => _currentUser;

  String get displayName {
    final name = _currentUser?.displayName.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'BlightScan User';
  }

  String get displayEmail => _currentUser?.email ?? 'Not signed in';

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final refreshToken = _prefs?.getString(_refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        _isReady = true;
        notifyListeners();
        return;
      }

      final restoredUser = await _identityService.refreshSession(
        refreshToken: refreshToken,
        fallbackUid: _prefs?.getString(_uidKey),
        fallbackName: _prefs?.getString(_displayNameKey),
        fallbackEmail: _prefs?.getString(_emailKey),
      );
      await _userProfileService.ensureUserProfile(restoredUser);
      _currentUser = restoredUser;
      _rememberMe = true;
      _tokenAcquiredAt = _now();
      await _persistUser(restoredUser);
    } on ProfileProvisioningException catch (error, stackTrace) {
      _logAuthFailure('session profile provisioning', error, stackTrace);
    } on AuthException catch (error, stackTrace) {
      _logAuthFailure('session restoration', error, stackTrace);
      if (!error.code.startsWith('network/')) {
        await signOut(notify: false);
      }
    } catch (error, stackTrace) {
      _logAuthFailure('session restoration', error, stackTrace);
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final user = await _identityService.signIn(
        email: email,
        password: password,
      );
      _traceCredentials(user, 'sign-in');
      await _userProfileService.ensureUserProfile(user);
      _currentUser = user;
      _rememberMe = rememberMe;
      _tokenAcquiredAt = _now();
      if (rememberMe) {
        await _persistUser(user);
      } else {
        await _clearPersistedUser();
      }
      notifyListeners();
      return const AuthActionResult.success('Logged in successfully.');
    } on AuthException catch (error, stackTrace) {
      _logAuthFailure('sign-in', error, stackTrace);
      return AuthActionResult.failure(error.message);
    } on ProfileProvisioningException catch (error, stackTrace) {
      _logAuthFailure('sign-in profile provisioning', error, stackTrace);
      return const AuthActionResult.failure(
        'Profile setup could not be completed. Please try again.',
      );
    } catch (error, stackTrace) {
      _logAuthFailure('sign-in', error, stackTrace);
      return const AuthActionResult.failure(
        'Unable to log in. Please try again.',
      );
    }
  }

  Future<AuthActionResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('[AUTH_TRACE] signup started');
    try {
      final user = await _identityService.createAccount(
        displayName: name,
        email: email,
        password: password,
      );
      debugPrint('[AUTH_TRACE] auth account creation completed');
      _traceCredentials(user, 'signup');
      await _userProfileService.ensureUserProfile(user);
      _currentUser = user;
      _rememberMe = true;
      _tokenAcquiredAt = _now();
      await _persistUser(user);
      notifyListeners();
      return const AuthActionResult.success('Account created successfully.');
    } on AuthException catch (error, stackTrace) {
      _logAuthFailure('signup', error, stackTrace);
      return AuthActionResult.failure(error.message);
    } on ProfileProvisioningException catch (error, stackTrace) {
      _logAuthFailure('signup profile provisioning', error, stackTrace);
      return const AuthActionResult.failure(
        'Your account was created, but profile setup could not be completed. Please sign in to retry.',
      );
    } catch (error, stackTrace) {
      _logAuthFailure('signup', error, stackTrace);
      return const AuthActionResult.failure(
        'Unable to create account. Please try again.',
      );
    }
  }

  Future<AuthActionResult> sendPasswordResetEmail(String email) async {
    try {
      await _identityService.sendPasswordResetEmail(email);
      return const AuthActionResult.success(
        'Password reset email sent. Please check your inbox.',
      );
    } on AuthException catch (error) {
      return AuthActionResult.failure(error.message);
    } catch (error, stackTrace) {
      _logAuthFailure('password reset', error, stackTrace);
      return const AuthActionResult.failure(
        'Unable to send reset email. Please try again.',
      );
    }
  }

  Future<AuthActionResult> updatePassword(String newPassword) async {
    final user = _currentUser;
    if (user == null) {
      return const AuthActionResult.failure('Please log in first.');
    }

    try {
      final updatedUser = await _identityService.updatePassword(
        user: user,
        newPassword: newPassword,
      );
      _currentUser = updatedUser;
      _tokenAcquiredAt = _now();
      if (_rememberMe) await _persistUser(updatedUser);
      notifyListeners();
      return const AuthActionResult.success('Password updated successfully.');
    } on AuthException catch (error) {
      return AuthActionResult.failure(error.message);
    } catch (error, stackTrace) {
      _logAuthFailure('password update', error, stackTrace);
      return const AuthActionResult.failure(
        'Unable to update password. Please try again.',
      );
    }
  }

  Future<void> signOut({bool notify = true}) async {
    _currentUser = null;
    _rememberMe = false;
    _tokenAcquiredAt = null;
    await _clearPersistedUser();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _persistUser(AuthUser user) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_uidKey, user.uid),
      prefs.setString(_emailKey, user.email),
      prefs.setString(_displayNameKey, user.displayName),
      prefs.setString(_refreshTokenKey, user.refreshToken),
    ]);
  }

  Future<void> _clearPersistedUser() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_uidKey),
      prefs.remove(_emailKey),
      prefs.remove(_displayNameKey),
      prefs.remove(_idTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
  }

  void _traceCredentials(AuthUser user, String flow) {
    debugPrint('[AUTH_TRACE] $flow UID = ${user.uid}');
    debugPrint(
        '[AUTH_TRACE] requesting ID token from Identity Toolkit response');
    debugPrint('[AUTH_TRACE] ID token acquired = ${user.idToken.isNotEmpty}');
    debugPrint('[AUTH_TRACE] ID token length = ${user.idToken.length}');
  }

  void _logAuthFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is AuthException) {
      debugPrint(
        '[AUTH_TRACE] $operation failed code=${error.code} message=${error.technicalMessage}',
      );
    } else if (error is ProfileProvisioningException) {
      debugPrint(
        '[AUTH_TRACE] $operation failed code=${error.code} message=${error.message}',
      );
    } else {
      debugPrint('[AUTH_TRACE] $operation failed: $error');
    }
    debugPrint(stackTrace.toString());
  }
}
