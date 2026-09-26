class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String caption;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy; // List of user UIDs

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.caption,
    required this.imageUrls,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedBy = const [],
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    List<String>? likedBy,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      caption: caption,
      imageUrls: imageUrls,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });
}
