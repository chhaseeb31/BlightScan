import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../domain/models/community_post.dart';

class CommunityService extends ChangeNotifier {
  CommunityService({
    required this.authSession,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String _communityCollection = 'community_posts';

  final AuthSessionService authSession;
  final http.Client _client;

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _loadError;
  String? uploadError;

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get hasAuth =>
      authSession.isSignedIn &&
      authSession.currentUser?.idToken != null &&
      authSession.currentUser!.idToken.isNotEmpty;

  String get _uid => authSession.currentUser?.uid ?? '';
  final Set<String> _likingPosts = {};

  Future<String?> uploadPostImage(File imageFile) async {
    uploadError = null;
    if (!hasAuth) {
      uploadError = 'Please sign in before uploading a photo.';
      debugPrint(
          '[CommunityService] uploadPostImage blocked: no authenticated user');
      return null;
    }

    try {
      final token = await authSession.getValidIdToken();
      if (token == null) return null;
      final bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty || bytes.length >= 10 * 1024 * 1024) {
        uploadError = 'Choose a photo smaller than 10 MB.';
        return null;
      }
      final isPng = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
      final isJpeg = bytes.length > 3 && bytes[0] == 0xff && bytes[1] == 0xd8;
      if (!isPng && !isJpeg) {
        uploadError = 'Please choose a JPEG or PNG photo.';
        return null;
      }
      final contentType = isPng ? 'image/png' : 'image/jpeg';
      final name =
          'community_posts/$_uid/${DateTime.now().microsecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}';
      final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket!;
      final boundary = 'blightscan_${DateTime.now().microsecondsSinceEpoch}';
      final metadata = jsonEncode({'name': name, 'contentType': contentType});
      final body = <int>[
        ...utf8.encode(
            '--$boundary\r\nContent-Type: application/json; charset=utf-8\r\n\r\n$metadata\r\n--$boundary\r\nContent-Type: $contentType\r\n\r\n'),
        ...bytes,
        ...utf8.encode('\r\n--$boundary--'),
      ];
      final response = await _client
          .post(
            Uri.https('firebasestorage.googleapis.com', '/v0/b/$bucket/o',
                {'name': name}),
            headers: {
              'Authorization': 'Firebase $token',
              'X-Goog-Upload-Protocol': 'multipart',
              'Content-Type': 'multipart/related; boundary=$boundary',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        uploadError = response.statusCode == 404
            ? 'Photo storage is not available yet. You can publish without a photo.'
            : response.statusCode == 403
                ? 'Photo upload access is unavailable. Please contact support.'
                : 'Photo upload failed. Please try again.';
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final downloadToken =
          (data['downloadTokens'] as String? ?? '').split(',').first;
      if (downloadToken.isEmpty) return null;
      final url =
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(name)}?alt=media&token=${Uri.encodeComponent(downloadToken)}';
      return url;
    } catch (error, stackTrace) {
      uploadError = 'Photo upload failed. Check your connection and try again.';
      debugPrint('[CommunityService] uploadPostImage failed: $error');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  Future<void> loadPosts() async {
    if (_isLoading) return;
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      _loadError = 'Please sign in to view community posts.';
      _posts = [];
      _setLoading(false);
      notifyListeners();
      return;
    }

    _loadError = null;
    _setLoading(true);
    debugPrint('[CommunityService] loadPosts started for uid=$_uid');
    debugPrint('[CommunityService] Firestore path: $_communityCollection');

    try {
      final response = await _client
          .get(
            _documentsUri(_communityCollection, {
              'orderBy': 'createdAt desc',
              'pageSize': '50',
            }),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] loadPosts response status=${response.statusCode} reason=${response.reasonPhrase}',
      );

      if (response.statusCode == 404) {
        _posts = [];
        _loadError = null;
        notifyListeners();
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        _loadError = response.statusCode == 403
            ? 'Community access is blocked by server permissions. Please contact support.'
            : 'Your session has expired. Please sign in again.';
        debugPrint('[CommunityService] loadPosts permission denied');
        debugPrint('[CommunityService] response body=${response.body}');
        notifyListeners();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Firestore load failed with status ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : (decoded as Map).cast<String, dynamic>();
      final docs = body['documents'] as List<dynamic>? ?? [];
      debugPrint(
          '[CommunityService] loadPosts documents received=${docs.length}');

      _posts = docs
          .whereType<Map<String, dynamic>>()
          .map(_postFromDocument)
          .where((post) => post.id.isNotEmpty)
          .toList();
      _posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _loadError = null;
      notifyListeners();
    } on TimeoutException catch (error, stackTrace) {
      _loadError = 'Community is temporarily unavailable. Please retry.';
      debugPrint('[CommunityService] loadPosts timed out: $error');
      debugPrint(stackTrace.toString());
      notifyListeners();
    } catch (error, stackTrace) {
      _loadError = 'Unable to load community posts. Please retry.';
      debugPrint('[CommunityService] loadPosts failed: $error');
      debugPrint(stackTrace.toString());
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPost({
    required String caption,
    required List<String> imageUrls,
  }) async {
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[CommunityService] createPost blocked: no authenticated user');
      return false;
    }

    final id = 'post_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toUtc();

    try {
      final response = await _client
          .post(
            _documentsUri(_communityCollection, {'documentId': id}),
            headers: _headers(token),
            body: jsonEncode({
              'fields': {
                'id': {'stringValue': id},
                'authorId': {'stringValue': _uid},
                'authorName': {'stringValue': authSession.displayName},
                'authorPhotoUrl': {'stringValue': ''},
                'caption': {'stringValue': caption},
                'imageUrls': {
                  'arrayValue': {
                    'values':
                        imageUrls.map((url) => {'stringValue': url}).toList()
                  }
                },
                'createdAt': {'timestampValue': now.toIso8601String()},
                'updatedAt': {'timestampValue': now.toIso8601String()},
                'likeCount': {'integerValue': '0'},
                'commentCount': {'integerValue': '0'},
                'likedBy': {
                  'arrayValue': {'values': []}
                },
              }
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] createPost response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final newPost = CommunityPost(
          id: id,
          authorId: _uid,
          authorName: authSession.displayName,
          caption: caption,
          imageUrls: imageUrls,
          createdAt: now.toLocal(),
          likedBy: const [],
        );
        _posts.insert(0, newPost);
        _loadError = null;
        notifyListeners();
        return true;
      }

      return false;
    } catch (error, stackTrace) {
      debugPrint('[CommunityService] createPost failed: $error');
      debugPrint(stackTrace.toString());
      return false;
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[CommunityService] toggleLike blocked: no authenticated user');
      return;
    }

    if (!_likingPosts.add(post.id)) return;
    final isLiked = post.isLikedBy(_uid);
    final newList = List<String>.from(post.likedBy);
    if (isLiked) {
      newList.remove(_uid);
    } else {
      newList.add(_uid);
    }

    final newLikeCount = newList.length;

    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post.copyWith(likedBy: newList, likeCount: newLikeCount);
      notifyListeners();
    }

    try {
      final response = await _client
          .patch(
            _documentsUri('$_communityCollection/${post.id}', {
              // Without a mask, PATCH replaces the document and loses post fields.
          'updateMask.fieldPaths': ['likedBy', 'likeCount'],
              'currentDocument.exists': 'true',
            }),
            headers: _headers(token),
            body: jsonEncode({
              'fields': {
                'likeCount': {'integerValue': '$newLikeCount'},
                'likedBy': {
                  'arrayValue': {
                    'values':
                        newList.map((uid) => {'stringValue': uid}).toList(),
                  }
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] toggleLike response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Like update failed: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      debugPrint('[CommunityService] toggleLike failed: $error');
      debugPrint(stackTrace.toString());
      if (index != -1) {
        final currentIndex = _posts.indexWhere((p) => p.id == post.id);
        if (currentIndex != -1) _posts[currentIndex] = post;
        notifyListeners();
      }
    } finally {
      _likingPosts.remove(post.id);
    }
  }

  Future<List<CommunityComment>> getComments(String postId) async {
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[CommunityService] getComments blocked: no authenticated user');
      return const [];
    }

    try {
      final response = await _client
          .get(
            _documentsUri('$_communityCollection/$postId/comments', {
              'orderBy': 'createdAt asc',
            }),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] getComments response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(response.body);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : (decoded as Map).cast<String, dynamic>();
      final docs = body['documents'] as List<dynamic>? ?? [];
      return docs
          .whereType<Map<String, dynamic>>()
          .map((doc) => _commentFromDocument(doc, postId))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('[CommunityService] getComments failed: $error');
      debugPrint(stackTrace.toString());
      return const [];
    }
  }

  Future<bool> addComment(String postId, String text) async {
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[CommunityService] addComment blocked: no authenticated user');
      return false;
    }

    final id = 'comment_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final response = await _client
          .post(
            _documentsUri(
                '$_communityCollection/$postId/comments', {'documentId': id}),
            headers: _headers(token),
            body: jsonEncode({
              'fields': {
                'id': {'stringValue': id},
                'authorId': {'stringValue': _uid},
                'authorName': {'stringValue': authSession.displayName},
                'text': {'stringValue': text},
                'createdAt': {'timestampValue': now},
              }
            }),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] addComment response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final index = _posts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = post.copyWith(commentCount: post.commentCount + 1);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (error, stackTrace) {
      debugPrint('[CommunityService] addComment failed: $error');
      debugPrint(stackTrace.toString());
      return false;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[CommunityService] deleteComment blocked: no authenticated user');
      return false;
    }

    try {
      final response = await _client
          .delete(
            _documentsUri('$_communityCollection/$postId/comments/$commentId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] deleteComment response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = post.copyWith(
          commentCount: post.commentCount > 0 ? post.commentCount - 1 : 0,
        );
        notifyListeners();
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('[CommunityService] deleteComment failed: $error');
      debugPrint(stackTrace.toString());
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    final token = await authSession.getValidIdToken();
    if (token == null || token.isEmpty) {
      debugPrint(
          '[CommunityService] deletePost blocked: no authenticated user');
      return false;
    }

    try {
      final response = await _client
          .delete(
            _documentsUri('$_communityCollection/$postId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[CommunityService] deletePost response status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _posts.removeWhere((post) => post.id == postId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (error, stackTrace) {
      debugPrint('[CommunityService] deletePost failed: $error');
      debugPrint(stackTrace.toString());
      return false;
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Uri _documentsUri(String path, [Map<String, dynamic>? query]) {
    return Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/${AppConfig.firebaseProjectId}/databases/(default)/documents/$path',
      query,
    );
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  CommunityPost _postFromDocument(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String? ?? '';
    final docId = name.split('/').last;

    final likedByValues =
        fields['likedBy']?['arrayValue']?['values'] as List<dynamic>? ?? [];
    final likedBy = likedByValues
        .map((value) =>
            (value as Map<String, dynamic>)['stringValue'] as String?)
        .whereType<String>()
        .toList();

    final imageUrlValues =
        fields['imageUrls']?['arrayValue']?['values'] as List<dynamic>? ?? [];
    final imageUrls = imageUrlValues
        .map((value) =>
            (value as Map<String, dynamic>)['stringValue'] as String?)
        .whereType<String>()
        .toList();

    return CommunityPost(
      id: docId,
      authorId: fields['authorId']?['stringValue'] ?? '',
      authorName: fields['authorName']?['stringValue'] ?? 'Anonymous',
      authorPhotoUrl: fields['authorPhotoUrl']?['stringValue'],
      caption: fields['caption']?['stringValue'] ?? '',
      imageUrls: imageUrls,
      createdAt: _dateField(fields['createdAt']),
      likeCount: int.tryParse(fields['likeCount']?['integerValue'] ?? '0') ?? 0,
      commentCount:
          int.tryParse(fields['commentCount']?['integerValue'] ?? '0') ?? 0,
      likedBy: likedBy,
    );
  }

  CommunityComment _commentFromDocument(
    Map<String, dynamic> doc,
    String postId,
  ) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String? ?? '';
    final docId = name.split('/').last;

    return CommunityComment(
      id: docId,
      postId: postId,
      authorId: fields['authorId']?['stringValue'] ?? '',
      authorName: fields['authorName']?['stringValue'] ?? 'Anonymous',
      text: fields['text']?['stringValue'] ?? '',
      createdAt: _dateField(fields['createdAt']),
    );
  }

  DateTime _dateField(dynamic value) {
    if (value is Map<String, dynamic>) {
      final timestamp = value['timestampValue'];
      if (timestamp is String) {
        return DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
      }
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
