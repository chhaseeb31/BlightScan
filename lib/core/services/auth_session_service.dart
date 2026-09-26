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
  })  : _identityService = identityService ?? FirebaseIdentityService(),
        _userProfileService = userProfileService ?? FirebaseUserProfileService();

  static const String _uidKey = 'auth.uid';
  static const String _emailKey = 'auth.email';
  static const String _displayNameKey = 'auth.displayName';
  static const String _idTokenKey = 'auth.idToken';
  static const String _refreshTokenKey = 'auth.refreshToken';

  final FirebaseIdentityService _identityService;
  final FirebaseUserProfileService _userProfileService;
  SharedPreferences? _prefs;
  AuthUser? _currentUser;
  bool _isReady = false;

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
    _prefs = await SharedPreferences.getInstance();
    final refreshToken = _prefs?.getString(_refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      _isReady = true;
      notifyListeners();
      return;
    }

    try {
      _currentUser = await _identityService.refreshSession(
        refreshToken: refreshToken,
        fallbackName: _prefs?.getString(_displayNameKey),
        fallbackEmail: _prefs?.getString(_emailKey),
      );
      await _persistUser(_currentUser!);
    } catch (_) {
      await signOut(notify: false);
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
      _currentUser = user;
      unawaited(_userProfileService.upsertUser(user));
      if (rememberMe) {
        await _persistUser(user);
      } else {
        await _clearPersistedUser();
      }
      notifyListeners();
      return const AuthActionResult.success('Logged in successfully.');
    } on AuthException catch (error) {
      return AuthActionResult.failure(error.message);
    } catch (_) {
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
    try {
      final user = await _identityService.createAccount(
        displayName: name,
        email: email,
        password: password,
      );
      _currentUser = user;
      unawaited(_userProfileService.upsertUser(user));
      await _persistUser(user);
      notifyListeners();
      return const AuthActionResult.success('Account created successfully.');
    } on AuthException catch (error) {
      return AuthActionResult.failure(error.message);
    } catch (_) {
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
    } catch (_) {
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
      await _persistUser(updatedUser);
      notifyListeners();
      return const AuthActionResult.success('Password updated successfully.');
    } on AuthException catch (error) {
      return AuthActionResult.failure(error.message);
    } catch (_) {
      return const AuthActionResult.failure(
        'Unable to update password. Please try again.',
      );
    }
  }

  Future<void> signOut({bool notify = true}) async {
    _currentUser = null;
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
      prefs.setString(_idTokenKey, user.idToken),
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
}
