import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/widgets/gs_app_bar.dart';
import '../../domain/models/community_post.dart';
import '../../data/services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityService>().loadPosts();
    });
  }

  Future<void> _refresh() async {
    await context.read<CommunityService>().loadPosts();
  }

  Future<void> _showComments(CommunityPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityService = context.watch<CommunityService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GSAppBar(
        title: 'Community',
        showBack: false,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await context.push(AppRoutes.createPost);
              if (result == true) {
                _refresh();
              }
            },
            icon: const Icon(Icons.add_box_outlined, color: AppColors.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: communityService.isLoading && communityService.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : communityService.loadError != null &&
                    communityService.posts.isEmpty
                ? _CommunityError(
                    message: communityService.loadError!,
                    onRetry: _refresh,
                  )
                : communityService.posts.isEmpty
                    ? const _EmptyCommunity()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: communityService.posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final post = communityService.posts[index];
                          return _CommunityPostCard(
                            post: post,
                            onLike: () => communityService.toggleLike(post),
                            onComments: () => _showComments(post),
                            onDelete: post.authorId ==
                                    context
                                        .read<AuthSessionService>()
                                        .currentUser
                                        ?.uid
                                ? () async {
                                    await communityService.deletePost(post.id);
                                  }
                                : null,
                          );
                        },
                      ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final Future<void> Function()? onDelete;

  const _CommunityPostCard({
    required this.post,
    required this.onLike,
    required this.onComments,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSessionService>();
    final isLiked = post.isLikedBy(session.currentUser?.uid ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    post.authorName[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: AppTextStyles.titleSmall),
                      Text(
                        DateFormat.yMMMd().format(post.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await onDelete!();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete post'),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          if (post.imageUrls.isNotEmpty)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                image: DecorationImage(
                  image: NetworkImage(post.imageUrls.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.caption, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ActionButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${post.likeCount}',
                      color:
                          isLiked ? AppColors.error : AppColors.textSecondary,
                      onTap: onLike,
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${post.commentCount}',
                      onTap: onComments,
                    ),
                    const Spacer(),
                    const Icon(Icons.share_outlined,
                        color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: color ?? AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;

  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  late Future<List<CommunityComment>> _commentsFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture =
        context.read<CommunityService>().getComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || text.length > 500 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final service = context.read<CommunityService>();
    final success = await service.addComment(widget.post.id, text);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (success) {
        _commentController.clear();
        _commentsFuture = service.getComments(widget.post.id);
      }
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add comment. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currentUid = context.read<AuthSessionService>().currentUser?.uid;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Material(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text('Comments', style: AppTextStyles.titleMedium),
                      const Spacer(),
                      Text('${widget.post.commentCount}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<CommunityComment>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments =
                          snapshot.data ?? const <CommunityComment>[];
                      if (comments.isEmpty) {
                        return const Center(
                          child:
                              Text('No comments yet. Start the conversation.'),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primarySurface,
                              child: Text(comment.authorName.isEmpty
                                  ? '?'
                                  : comment.authorName[0].toUpperCase()),
                            ),
                            title: Text(comment.authorName,
                                style: AppTextStyles.titleSmall),
                            subtitle: Text(comment.text),
                            trailing: comment.authorId == currentUid
                                ? IconButton(
                                    tooltip: 'Delete comment',
                                    onPressed: () async {
                                      final deleted = await context
                                          .read<CommunityService>()
                                          .deleteComment(
                                              widget.post.id, comment.id);
                                      if (deleted && mounted) {
                                        setState(() {
                                          _commentsFuture = context
                                              .read<CommunityService>()
                                              .getComments(widget.post.id);
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLength: 500,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              counterText: '',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Post comment',
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.border),
          SizedBox(height: 16),
          Text('No community posts yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Be the first to share your tomato progress!',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CommunityError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _CommunityError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
