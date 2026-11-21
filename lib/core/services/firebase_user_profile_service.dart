import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'firebase_identity_service.dart';

class ProfileProvisioningException implements Exception {
  const ProfileProvisioningException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class FirestoreRestException extends ProfileProvisioningException {
  const FirestoreRestException({
    required this.statusCode,
    required String code,
    required String message,
  }) : super(code, message);

  final int statusCode;
}

/// Creates/updates the Firestore user profile document after Firebase Auth.
/// This app uses Firebase Identity Toolkit and Firestore REST APIs directly.
class FirebaseUserProfileService {
  FirebaseUserProfileService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> ensureUserProfile(AuthUser user) async {
    final uid = user.uid.trim();
    final idToken = user.idToken.trim();
    debugPrint('[AUTH_TRACE] provisioning started');
    debugPrint('[AUTH_TRACE] provisioning path = /users/$uid');
    debugPrint('[AUTH_TRACE] UID available = ${uid.isNotEmpty}');
    debugPrint('[AUTH_TRACE] ID token acquired = ${idToken.isNotEmpty}');
    debugPrint('[AUTH_TRACE] ID token length = ${idToken.length}');

    if (uid.isEmpty) {
      throw const ProfileProvisioningException(
        'auth/empty-uid',
        'The authenticated account did not provide a UID.',
      );
    }
    if (idToken.isEmpty) {
      throw const ProfileProvisioningException(
        'auth/empty-id-token',
        'The authenticated account did not provide an ID token.',
      );
    }

    final userDocPath = 'users/$uid';
    final documentUri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${AppConfig.firebaseProjectId}/databases/(default)/documents/$userDocPath',
    );
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final check = await _client
          .get(
            documentUri,
            headers: _headers(idToken),
          )
          .timeout(const Duration(seconds: 15));

      if (check.statusCode != 200 && check.statusCode != 404) {
        throw _firestoreError('Profile existence check failed', check);
      }

      final isNewDocument = check.statusCode == 404;
      final fields = <String, dynamic>{
        'uid': {'stringValue': uid},
        'name': {'stringValue': user.displayName},
        'email': {'stringValue': user.email},
        'primaryCrop': {'stringValue': 'Tomato'},
        'projectScope': {'stringValue': 'Tomato Late Blight Detection'},
        'updatedAt': {'timestampValue': now},
      };
      if (isNewDocument) {
        fields['createdAt'] = {'timestampValue': now};
      }

      final response = await _client
          .patch(
            documentUri.replace(
              queryParameters: {
                'updateMask.fieldPaths': fields.keys.toList(),
              },
            ),
            headers: _headers(idToken),
            body: jsonEncode({'fields': fields}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _firestoreError('Profile write failed', response);
      }

      debugPrint('[AUTH_TRACE] provisioning completed');

      final verification = await _client
          .get(documentUri, headers: _headers(idToken))
          .timeout(const Duration(seconds: 15));
      if (verification.statusCode != 200) {
        throw _firestoreError('Profile verification failed', verification);
      }

      final body = jsonDecode(verification.body) as Map<String, dynamic>;
      final verifiedUid =
          (body['fields'] as Map<String, dynamic>?)?['uid']?['stringValue'];
      if (verifiedUid != uid) {
        throw const ProfileProvisioningException(
          'profile/uid-mismatch',
          'The saved profile UID did not match the authenticated UID.',
        );
      }

      debugPrint('[AUTH_TRACE] provisioning verification completed');
      return true;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('[AUTH_TRACE] provisioning failed: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    } catch (error, stackTrace) {
      if (error is ProfileProvisioningException) {
        debugPrint(
          '[AUTH_TRACE] provisioning failed code=${error.code} message=${error.message}',
        );
      } else {
        debugPrint('[AUTH_TRACE] provisioning failed: $error');
      }
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Uri _photoUri(String uid) => Uri.https('firestore.googleapis.com',
      '/v1/projects/${AppConfig.firebaseProjectId}/databases/(default)/documents/users/$uid');

  Future<String?> fetchPhotoUrl(AuthUser user) async {
    final response = await _client
        .get(_photoUri(user.uid), headers: _headers(user.idToken))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200)
      throw _firestoreError('Profile read failed', response);
    return jsonDecode(response.body)['fields']?['photoUrl']?['stringValue']
        as String?;
  }

  Future<void> updatePhotoUrl(AuthUser user, String url) async {
    final response = await _client
        .patch(
          _photoUri(user.uid)
              .replace(queryParameters: {'updateMask.fieldPaths': 'photoUrl'}),
          headers: _headers(user.idToken),
          body: jsonEncode({
            'fields': {
              'photoUrl': {'stringValue': url}
            }
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _firestoreError('Profile photo save failed', response);
    }
  }

  Future<void> upsertUser(AuthUser user) async {
    final ok = await ensureUserProfile(user);
    if (!ok) {
      throw StateError('User profile provisioning failed for uid=${user.uid}');
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  FirestoreRestException _firestoreError(
    String operation,
    http.Response response,
  ) {
    var code = response.statusCode.toString();
    var message = response.body;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        code = error['status']?.toString() ?? error['code']?.toString() ?? code;
        message = error['message']?.toString() ?? message;
      }
    } on FormatException {
      // Keep a non-JSON backend response as the diagnostic message.
    }
    return FirestoreRestException(
      statusCode: response.statusCode,
      code: code,
      message: '$operation: $message',
    );
  }

  void dispose() => _client.close();
}
