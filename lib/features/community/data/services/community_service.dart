import 'dart:async';
import 'dart:convert';
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

  final AuthSessionService authSession;
  final http.Client _client;

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _loadError;

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  String get _uid => authSession.currentUser?.uid ?? '';
  String? get _token => authSession.currentUser?.idToken;

  Future<void> loadPosts() async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    _loadError = null;
    _setLoading(true);
    try {
      final response = await _client
          .get(
            _documentsUri('community_posts', {
              'orderBy': 'createdAt desc',
              'pageSize': '50',
            }),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _loadError = response.statusCode == 403
            ? 'Community access is currently unavailable.'
            : 'Unable to load community posts.';
        debugPrint('[Community] Load failed: ${response.statusCode}');
        notifyListeners();
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = body['documents'] as List<dynamic>? ?? [];
      _posts = docs
          .whereType<Map<String, dynamic>>()
          .map(_postFromDocument)
          .toList();
      notifyListeners();
    } catch (e) {
      _loadError = 'Unable to load community posts. Check your connection.';
      debugPrint('[Community] Load error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPost({
    required String caption,
    required List<String> imageUrls,
  }) async {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    final id = 'post_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toUtc();

    try {
      final response = await _client
          .post(
            _documentsUri('community_posts', {'documentId': id}),
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
                'likeCount': {'integerValue': '0'},
                'commentCount': {'integerValue': '0'},
                'likedBy': {
                  'arrayValue': {'values': []}
                },
              }
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Optimistic local update
        final newPost = CommunityPost(
          id: id,
          authorId: _uid,
          authorName: authSession.displayName,
          caption: caption,
          imageUrls: imageUrls,
          createdAt: now.toLocal(),
          likedBy: [],
        );
        _posts.insert(0, newPost);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Community] Create post failed: $e');
      return false;
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    final isLiked = post.isLikedBy(_uid);
    final newList = List<String>.from(post.likedBy);
    if (isLiked) {
      newList.remove(_uid);
    } else {
      newList.add(_uid);
    }

    final newLikeCount = newList.length;

    // Optimistic local update
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post.copyWith(likedBy: newList, likeCount: newLikeCount);
      notifyListeners();
    }

    try {
      final response = await _client.patch(
        _documentsUri('community_posts/${post.id}'),
        headers: _headers(token),
        body: jsonEncode({
          'fields': {
            'likeCount': {'integerValue': '$newLikeCount'},
            'likedBy': {
              'arrayValue': {
                'values': newList.map((uid) => {'stringValue': uid}).toList()
              }
            },
          },
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Like update failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Community] Toggle like failed: $e');
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post;
        notifyListeners();
      }
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<List<CommunityComment>> getComments(String postId) async {
    final token = _token;
    if (token == null || token.isEmpty) return [];

    try {
      final response = await _client
          .get(
            _documentsUri('community_posts/$postId/comments', {
              'orderBy': 'createdAt asc',
            }),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = body['documents'] as List<dynamic>? ?? [];
      return docs
          .whereType<Map<String, dynamic>>()
          .map((doc) => _commentFromDocument(doc, postId))
          .toList();
    } catch (e) {
      debugPrint('[Community] Load comments failed: $e');
      return [];
    }
  }

  Future<bool> addComment(String postId, String text) async {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    final id = 'comment_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final response = await _client.post(
        _documentsUri('community_posts/$postId/comments', {'documentId': id}),
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
    } catch (e) {
      debugPrint('[Community] Add comment failed: $e');
      return false;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    try {
      final response = await _client.delete(
        _documentsUri('community_posts/$postId/comments/$commentId'),
        headers: _headers(token),
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
    } catch (e) {
      debugPrint('[Community] Delete comment failed: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    try {
      final response = await _client.delete(
        _documentsUri('community_posts/$postId'),
        headers: _headers(token),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _posts.removeWhere((post) => post.id == postId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[Community] Delete post failed: $e');
      return false;
    }
  }

  Uri _documentsUri(String path, [Map<String, String>? query]) {
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
    final likedBy =
        likedByValues.map((v) => v['stringValue'] as String).toList();

    final imageUrlValues =
        fields['imageUrls']?['arrayValue']?['values'] as List<dynamic>? ?? [];
    final imageUrls =
        imageUrlValues.map((v) => v['stringValue'] as String).toList();

    return CommunityPost(
      id: docId,
      authorId: fields['authorId']?['stringValue'] ?? '',
      authorName: fields['authorName']?['stringValue'] ?? 'Anonymous',
      authorPhotoUrl: fields['authorPhotoUrl']?['stringValue'],
      caption: fields['caption']?['stringValue'] ?? '',
      imageUrls: imageUrls,
      createdAt: DateTime.tryParse(fields['createdAt']?['timestampValue'] ?? '')
              ?.toLocal() ??
          DateTime.now(),
      likeCount: int.tryParse(fields['likeCount']?['integerValue'] ?? '0') ?? 0,
      commentCount:
          int.tryParse(fields['commentCount']?['integerValue'] ?? '0') ?? 0,
      likedBy: likedBy,
    );
  }

  CommunityComment _commentFromDocument(
      Map<String, dynamic> doc, String postId) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final name = doc['name'] as String? ?? '';
    final docId = name.split('/').last;

    return CommunityComment(
      id: docId,
      postId: postId,
      authorId: fields['authorId']?['stringValue'] ?? '',
      authorName: fields['authorName']?['stringValue'] ?? 'Anonymous',
      text: fields['text']?['stringValue'] ?? '',
      createdAt: DateTime.tryParse(fields['createdAt']?['timestampValue'] ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
