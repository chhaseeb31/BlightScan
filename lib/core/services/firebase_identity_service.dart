import 'dart:async';
import 'dart:convert';

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
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackRefreshToken,
  }) {
    return AuthUser(
      uid: _readString(data, ['localId', 'user_id']),
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

  const AuthException(this.message);

  @override
  String toString() => message;
}

class FirebaseIdentityService {
  FirebaseIdentityService({http.Client? client}) : _client = client ?? http.Client();

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
    final data = await _postJson(
      _identityUri('accounts:signInWithPassword'),
      {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );
    return AuthUser.fromIdentityResponse(data);
  }

  Future<AuthUser> createAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final data = await _postJson(
      _identityUri('accounts:signUp'),
      {
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      },
    );

    final createdUser = AuthUser.fromIdentityResponse(
      data,
      fallbackName: displayName.trim(),
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

    return AuthUser.fromIdentityResponse(
      data,
      fallbackName: displayName.trim(),
      fallbackEmail: user.email,
      fallbackRefreshToken: user.refreshToken,
    );
  }

  Future<AuthUser> refreshSession({
    required String refreshToken,
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    final response = await _client
        .post(
          _refreshUri,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);
    return AuthUser.fromIdentityResponse(
      data,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
      fallbackRefreshToken: refreshToken,
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

    return AuthUser.fromIdentityResponse(
      data,
      fallbackName: user.displayName,
      fallbackEmail: user.email,
      fallbackRefreshToken: user.refreshToken,
    );
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
    } on TimeoutException {
      throw const AuthException('Request timed out. Please try again.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Network error. Please check your connection.');
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
    throw AuthException(_friendlyMessage(message));
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
