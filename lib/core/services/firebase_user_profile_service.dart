import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'firebase_identity_service.dart';

/// Creates/updates the Firestore user profile document after Firebase Auth.
/// Uses Firestore REST API to avoid adding unnecessary wrapper code.
class FirebaseUserProfileService {
  FirebaseUserProfileService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> upsertUser(AuthUser user) async {
    if (user.uid.isEmpty || user.idToken.isEmpty) return;

    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${AppConfig.firebaseProjectId}/databases/(default)/documents:commit',
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final documentName =
        'projects/${AppConfig.firebaseProjectId}/databases/(default)/documents/users/${user.uid}';

    final body = {
      'writes': [
        {
          'update': {
            'name': documentName,
            'fields': {
              'uid': {'stringValue': user.uid},
              'name': {'stringValue': user.displayName},
              'email': {'stringValue': user.email},
              'primaryCrop': {'stringValue': 'Tomato'},
              'projectScope': {'stringValue': 'Tomato Late Blight Detection'},
              'updatedAt': {'timestampValue': now},
            },
          },
          'updateMask': {
            'fieldPaths': [
              'uid',
              'name',
              'email',
              'primaryCrop',
              'projectScope',
              'updatedAt',
            ],
          },
        }
      ],
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer ${user.idToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[UserProfile] Firestore upsert failed: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('[UserProfile] Firestore upsert timed out.');
    } catch (e) {
      debugPrint('[UserProfile] Firestore upsert skipped: $e');
    }
  }

  void dispose() => _client.close();
}
