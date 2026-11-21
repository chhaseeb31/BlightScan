import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/app_routes.dart';
import '../../domain/models/community_post.dart';
import '../../data/services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _filter = 'Latest';
  String _query = '';
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CommunityService>().loadPosts();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => context.read<CommunityService>().loadPosts();
  Future<void> _createPost() async {
    final created = await context.push(AppRoutes.createPost);
    if (mounted && created == true) await _refresh();
  }

  Future<void> _delete(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete this post?'),
              content:
                  const Text('This will remove your post from the community.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep post')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.error)))
              ],
            ));
    if (confirmed != true || !mounted) return;
    final success = await context.read<CommunityService>().deletePost(post.id);
    if (mounted && !success)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not delete post. Please try again.')));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CommunityService>();
    final session = context.watch<AuthSessionService>();
    final posts = service.posts.where((post) {
      final matches = '${post.caption} ${post.authorName}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      return matches &&
          (_filter != 'My posts' ||
              post.authorId == session.currentUser?.uid) &&
          (_filter != 'With photos' || post.imageUrls.isNotEmpty);
    }).toList();
    posts.sort((a, b) => _filter == 'Most liked' && a.likeCount != b.likeCount
        ? b.likeCount.compareTo(a.likeCount)
        : b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GROW BETTER, TOGETHER',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.8,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700)),
              Text('Community',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ]),
        toolbarHeight: 80,
        actions: [
          IconButton(
              tooltip: 'Community guidelines',
              icon: const Icon(Icons.info_outline_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                        title: Text('A little kindness grows a lot'),
                        content: Text(
                            'Share your experience, ask thoughtful questions, and respect other growers. Include a clear photo and growing conditions when asking for help. Confirm treatment advice with a local agriculture expert.'),
                      ))),
          const SizedBox(width: 8)
        ],
      ),
      body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(24)),
                                child: Row(children: [
                                  const Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            'Your patch of\nthe growing world.',
                                            style: TextStyle(
                                                color: AppColors.textOnPrimary,
                                                fontSize: 25,
                                                height: 1.2,
                                                fontWeight: FontWeight.w700)),
                                        SizedBox(height: 10),
                                        Text(
                                            'Small discoveries. Better harvests.\nShare what’s growing with you.',
                                            style: TextStyle(
                                                color: AppColors.textOnPrimary,
                                                fontSize: 13,
                                                height: 1.5)),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: const BoxDecoration(
                                          color: AppColors.primarySurface,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.eco_rounded,
                                          color: AppColors.primary, size: 36)),
                                ])),
                            const SizedBox(height: 16),
                            _Surface(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(children: [
                                      InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: _createPost,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Row(children: [
                                                _Avatar(
                                                    name: session.displayName),
                                                const SizedBox(width: 12),
                                                const Expanded(
                                                    child: Text(
                                                        'What’s growing today?',
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontSize: 15))),
                                                const Icon(Icons.edit_outlined,
                                                    color:
                                                        AppColors.primaryDark,
                                                    size: 20),
                                              ]))),
                                      const Divider(height: 24),
                                      Row(children: [
                                        const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: AppColors.primaryDark,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                            child: Text(
                                                'A question, a photo, a win.',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary))),
                                        FilledButton(
                                            onPressed: _createPost,
                                            style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor:
                                                    AppColors.textOnPrimary),
                                            child: const Text('Post')),
                                      ]),
                                    ]))),
                            const SizedBox(height: 24),
                            const Row(children: [
                              Expanded(
                                  child: Text('From the community',
                                      style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary))),
                              SizedBox(width: 12),
                              Icon(Icons.forum_outlined,
                                  color: AppColors.primaryDark, size: 22)
                            ]),
                            const SizedBox(height: 14),
                            TextField(
                                controller: _search,
                                onChanged: (value) =>
                                    setState(() => _query = value.trim()),
                                decoration: InputDecoration(
                                  hintText: 'Search loaded posts or growers',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            _search.clear();
                                            setState(() => _query = '');
                                          }),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none),
                                )),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                    children: [
                                  'Latest',
                                  'Most liked',
                                  'With photos',
                                  'My posts'
                                ]
                                        .map((filter) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: ChoiceChip(
                                              label: Text(filter),
                                              selected: _filter == filter,
                                              showCheckmark: false,
                                              selectedColor: AppColors.primary,
                                              backgroundColor:
                                                  AppColors.surface,
                                              side: BorderSide(
                                                  color: _filter == filter
                                                      ? AppColors.primary
                                                      : AppColors.border),
                                              labelStyle: TextStyle(
                                                  color: _filter == filter
                                                      ? AppColors.textOnPrimary
                                                      : AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                              onSelected: (_) => setState(
                                                  () => _filter = filter),
                                            )))
                                        .toList())),
                          ]))),
              if (service.isLoading)
                const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                        minHeight: 2, color: AppColors.primary)),
              if (service.loadError != null)
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _Surface(
                            child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(children: [
                                  const Icon(Icons.cloud_off_outlined,
                                      color: AppColors.textSecondary, size: 32),
                                  const SizedBox(height: 12),
                                  Text(service.loadError!,
                                      textAlign: TextAlign.center),
                                  TextButton.icon(
                                      onPressed: _refresh,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Try again')),
                                ]))))),
              if (posts.isEmpty &&
                  !service.isLoading &&
                  service.loadError == null)
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: _Surface(
                            child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(children: [
                                  const Icon(Icons.spa_outlined,
                                      color: AppColors.primaryDark, size: 44),
                                  const SizedBox(height: 14),
                                  Text(
                                      service.posts.isEmpty
                                          ? 'Every community starts\nwith one conversation.'
                                          : 'No posts here yet',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 10),
                                  Text(
                                      service.posts.isEmpty
                                          ? 'Introduce your garden, ask a question,\nor share your first tomato.'
                                          : 'Try another filter or a different search.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          height: 1.5)),
                                  const SizedBox(height: 18),
                                  OutlinedButton.icon(
                                      onPressed: _createPost,
                                      icon: const Icon(Icons.add),
                                      label:
                                          const Text('Start a conversation')),
                                ]))))),
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    final post = posts[index];
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CommunityPostCard(
                          key: ValueKey(post.id),
                          post: post,
                          onLike: () => service.toggleLike(post),
                          onComments: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _CommentsSheet(post: post)),
                          onDelete: post.authorId == session.currentUser?.uid
                              ? () => _delete(post)
                              : null,
                        ));
                  }, childCount: posts.length))),
            ],
          )),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: child);
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primarySurface,
      child: Text(
          name.trim().isEmpty
              ? '?'
              : name.trim().characters.first.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700)));
}

class _CommunityPostCard extends StatefulWidget {
  const _CommunityPostCard(
      {super.key,
      required this.post,
      required this.onLike,
      required this.onComments,
      this.onDelete});
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback? onDelete;
  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final liked = post
        .isLikedBy(context.watch<AuthSessionService>().currentUser?.uid ?? '');
    return _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(children: [
            _Avatar(name: post.authorName),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(post.authorName.isEmpty ? 'Grower' : post.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(DateFormat('MMM d · h:mm a').format(post.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ])),
            PopupMenuButton<String>(
                tooltip: 'Post options',
                onSelected: (value) async {
                  if (value == 'delete') {
                    widget.onDelete?.call();
                    return;
                  }
                  await Clipboard.setData(ClipboardData(text: post.caption));
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post text copied')));
                },
                itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'copy', child: Text('Copy post text')),
                      if (widget.onDelete != null)
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete post',
                                style: TextStyle(color: AppColors.error)))
                    ]),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.caption,
                maxLines: _expanded ? null : 5,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: AppColors.textPrimary)),
            if (post.caption.length > 180 ||
                '\n'.allMatches(post.caption).length >= 5)
              TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Read more')),
          ])),
      if (post.imageUrls.isNotEmpty)
        SizedBox(
            height: 260,
            child: PageView(children: [
              for (var i = 0; i < post.imageUrls.length; i++)
                Stack(fit: StackFit.expand, children: [
                  Image.network(post.imageUrls[i],
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.background,
                          child: Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.textSecondary, size: 36)))),
                  if (post.imageUrls.length > 1)
                    Positioned(
                        right: 12,
                        top: 12,
                        child: Chip(
                            label: Text('${i + 1}/${post.imageUrls.length}'))),
                ])
            ])),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            Expanded(
                child: TextButton.icon(
                    onPressed: widget.onLike,
                    icon: Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20),
                    label: Text(post.likeCount > 0
                        ? '${post.likeCount} likes'
                        : 'Like'),
                    style: TextButton.styleFrom(
                        foregroundColor: liked
                            ? AppColors.error
                            : AppColors.textSecondary))),
            Container(height: 22, width: 1, color: AppColors.border),
            Expanded(
                child: TextButton.icon(
                    onPressed: widget.onComments,
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                    label: const Text('Comment'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary))),
          ])),
    ]));
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
