import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String idToken;
  final String refreshToken;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.idToken,
    required this.refreshToken,
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? idToken,
    String? refreshToken,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  factory AuthUser.fromIdentityResponse(
    Map<String, dynamic> data, {
    String? fallbackUid,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackRefreshToken,
  }) {
    return AuthUser(
      uid: _readString(data, ['localId', 'user_id'], fallback: fallbackUid),
      email: _readString(data, ['email'], fallback: fallbackEmail),
      displayName: _readString(
        data,
        ['displayName'],
        fallback: fallbackName ?? '',
      ),
      idToken: _readString(data, ['idToken', 'id_token', 'access_token']),
      refreshToken: _readString(
        data,
        ['refreshToken', 'refresh_token'],
        fallback: fallbackRefreshToken,
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String? fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return fallback ?? '';
  }
}

class AuthException implements Exception {
  final String message;
  final String code;
  final String technicalMessage;

  const AuthException(
    this.message, {
    this.code = 'auth/unknown',
    String? technicalMessage,
  }) : technicalMessage = technicalMessage ?? message;

  @override
  String toString() => message;
}

class FirebaseIdentityService {
  FirebaseIdentityService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  String get _apiKey => DefaultFirebaseOptions.currentPlatform.apiKey;

  Uri _identityUri(String method) => Uri.https(
        'identitytoolkit.googleapis.com',
        '/v1/$method',
        {'key': _apiKey},
      );

  Uri get _refreshUri => Uri.https(
        'securetoken.googleapis.com',
        '/v1/token',
        {'key': _apiKey},
      );

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('[AUTH_TRACE] requesting fresh Firebase ID token');
    final data = await _postJson(
      _identityUri('accounts:signInWithPassword'),
      {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );
    return _validatedUser(AuthUser.fromIdentityResponse(data), 'sign-in');
  }

  Future<AuthUser> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    debugPrint('[AUTH_TRACE] signup started');
    debugPrint('[AUTH_TRACE] requesting fresh Firebase ID token');
    final data = await _postJson(
      _identityUri('accounts:signUp'),
      {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );
    debugPrint('[AUTH_TRACE] Firebase Identity Toolkit signup completed');

    final createdUser = await _validatedUser(
      AuthUser.fromIdentityResponse(data, fallbackName: displayName.trim()),
      'signup',
    );

    if (displayName.trim().isEmpty) {
      return createdUser;
    }

    return updateDisplayName(
      user: createdUser,
      displayName: displayName.trim(),
    );
  }

  Future<AuthUser> updateDisplayName({
    required AuthUser user,
    required String displayName,
  }) async {
    final data = await _postJson(
      _identityUri('accounts:update'),
      {
        'idToken': user.idToken,
        'displayName': displayName.trim(),
        'returnSecureToken': true,
      },
    );

    return _validatedUser(
      AuthUser.fromIdentityResponse(
        data,
        fallbackUid: user.uid,
        fallbackName: displayName.trim(),
        fallbackEmail: user.email,
        fallbackRefreshToken: user.refreshToken,
      ),
      'display-name update',
    );
  }

  Future<AuthUser> refreshSession({
    required String refreshToken,
    String? fallbackUid,
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    final response = await _client.post(
      _refreshUri,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    ).timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);
    return _validatedUser(
      AuthUser.fromIdentityResponse(
        data,
        fallbackUid: fallbackUid,
        fallbackName: fallbackName,
        fallbackEmail: fallbackEmail,
        fallbackRefreshToken: refreshToken,
      ),
      'session refresh',
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _postJson(
      _identityUri('accounts:sendOobCode'),
      {
        'requestType': 'PASSWORD_RESET',
        'email': email.trim(),
      },
    );
  }

  Future<AuthUser> updatePassword({
    required AuthUser user,
    required String newPassword,
  }) async {
    final data = await _postJson(
      _identityUri('accounts:update'),
      {
        'idToken': user.idToken,
        'password': newPassword,
        'returnSecureToken': true,
      },
    );

    return _validatedUser(
      AuthUser.fromIdentityResponse(
        data,
        fallbackUid: user.uid,
        fallbackName: user.displayName,
        fallbackEmail: user.email,
        fallbackRefreshToken: user.refreshToken,
      ),
      'password update',
    );
  }

  Future<AuthUser> _validatedUser(AuthUser user, String operation) async {
    final hasUid = user.uid.isNotEmpty;
    if (!hasUid) {
      debugPrint('[AUTH_TRACE] $operation UID available = false');
      throw AuthException(
        'Firebase Authentication returned an incomplete account.',
        code: 'auth/empty-uid',
        technicalMessage: '$operation response did not contain a UID',
      );
    }

    if (user.idToken.isEmpty && user.refreshToken.isNotEmpty) {
      debugPrint(
        '[AUTH_TRACE] ID token missing from $operation response; requesting fresh token from Secure Token API',
      );
      user = await _refreshIdToken(user, operation);
    }

    final hasIdToken = user.idToken.isNotEmpty;
    debugPrint('[AUTH_TRACE] $operation auth response UID available = $hasUid');
    debugPrint('[AUTH_TRACE] $operation ID token acquired = $hasIdToken');
    debugPrint(
        '[AUTH_TRACE] $operation ID token length = ${user.idToken.length}');

    if (!hasIdToken) {
      throw AuthException(
        'Firebase Authentication did not provide an ID token.',
        code: 'auth/empty-id-token',
        technicalMessage:
            '$operation response has uid=$hasUid and idToken=false',
      );
    }
    return user;
  }

  Future<AuthUser> _refreshIdToken(AuthUser user, String operation) async {
    final response = await _client.post(
      _refreshUri,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': user.refreshToken,
      },
    ).timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    final refreshedUser = AuthUser.fromIdentityResponse(
      data,
      fallbackUid: user.uid,
      fallbackName: user.displayName,
      fallbackEmail: user.email,
      fallbackRefreshToken: user.refreshToken,
    );

    if (refreshedUser.uid != user.uid || refreshedUser.idToken.isEmpty) {
      throw AuthException(
        'Firebase Authentication could not refresh the ID token.',
        code: 'auth/token-refresh-incomplete',
        technicalMessage:
            '$operation token refresh UID matches=${refreshedUser.uid == user.uid}; ID token acquired=${refreshedUser.idToken.isNotEmpty}',
      );
    }
    debugPrint('[AUTH_TRACE] fresh Firebase ID token acquired = true');
    debugPrint(
      '[AUTH_TRACE] fresh Firebase ID token length = ${refreshedUser.idToken.length}',
    );
    return refreshedUser;
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _decodeResponse(response);
    } on TimeoutException catch (error, stackTrace) {
      _logRequestFailure(error, stackTrace);
      throw AuthException(
        'Request timed out. Please try again.',
        code: 'network/timeout',
        technicalMessage: error.toString(),
      );
    } on AuthException {
      rethrow;
    } catch (error, stackTrace) {
      _logRequestFailure(error, stackTrace);
      throw AuthException(
        'Network error. Please check your connection.',
        code: 'network/error',
        technicalMessage: error.toString(),
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final error = data['error'];
    final message = error is Map<String, dynamic>
        ? error['message'] as String? ?? 'AUTH_ERROR'
        : 'AUTH_ERROR';
    throw AuthException(
      _friendlyMessage(message),
      code: error is Map<String, dynamic>
          ? error['status']?.toString() ?? message
          : message,
      technicalMessage: message,
    );
  }

  void _logRequestFailure(Object error, StackTrace stackTrace) {
    debugPrint('[AUTH_TRACE] Identity Toolkit request failed: $error');
    debugPrint(stackTrace.toString());
  }

  String _friendlyMessage(String code) {
    if (code.startsWith('WEAK_PASSWORD')) {
      return 'Password is too weak. Use at least 8 characters.';
    }

    return switch (code) {
      'EMAIL_EXISTS' => 'This email is already registered.',
      'EMAIL_NOT_FOUND' => 'No account found for this email.',
      'INVALID_PASSWORD' => 'Incorrect password. Please try again.',
      'INVALID_LOGIN_CREDENTIALS' => 'Email or password is incorrect.',
      'INVALID_EMAIL' => 'Please enter a valid email address.',
      'USER_DISABLED' => 'This account has been disabled.',
      'TOO_MANY_ATTEMPTS_TRY_LATER' =>
        'Too many attempts. Please wait and try again.',
      'OPERATION_NOT_ALLOWED' =>
        'Email/password sign-in is not enabled in Firebase.',
      'MISSING_PASSWORD' => 'Please enter your password.',
      'TOKEN_EXPIRED' => 'Your session expired. Please log in again.',
      'INVALID_REFRESH_TOKEN' => 'Your session expired. Please log in again.',
      'CREDENTIAL_TOO_OLD_LOGIN_AGAIN' =>
        'Please log in again before changing your password.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  void dispose() {
    _client.close();
  }
}
