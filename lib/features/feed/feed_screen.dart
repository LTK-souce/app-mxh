import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/post_service.dart';
import '../../services/user_friend_service.dart';
import '../notifications/notification_screen.dart';
import '../search/ai_search_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  void _showCreatePostDialog(BuildContext context, UserModel currentUser) {
    final contentController = TextEditingController();
    String selectedVisibility = 'public';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tạo bài viết mới',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: currentUser.avatarUrl.isNotEmpty
                          ? NetworkImage(currentUser.avatarUrl)
                          : null,
                      child: currentUser.avatarUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      currentUser.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: PopupMenuButton<String>(
                      initialValue: selectedVisibility,
                      onSelected: (val) {
                        setDialogState(() => selectedVisibility = val);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedVisibility == 'public'
                                ? Icons.public
                                : Icons.group,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedVisibility == 'public'
                                ? 'Công khai'
                                : 'Bạn bè',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'public',
                          child: Row(
                            children: [
                              Icon(Icons.public, size: 18),
                              SizedBox(width: 8),
                              Text('Công khai'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'friends',
                          child: Row(
                            children: [
                              Icon(Icons.group, size: 18),
                              SizedBox(width: 8),
                              Text('Bạn bè'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Bạn đang nghĩ gì thế?',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // QUICK ATTACHMENT ACTION BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          tooltip: 'Thêm ảnh',
                          icon: const Icon(Icons.photo_library_rounded, color: Colors.green),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng thêm ảnh đang phát triển!')),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Gắn thẻ bạn bè',
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
                          onPressed: () {},
                        ),
                        IconButton(
                          tooltip: 'Cảm xúc / Hoạt động',
                          icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                          onPressed: () {},
                        ),
                        IconButton(
                          tooltip: 'Vị trí',
                          icon: const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) return;
                      await PostService().createPost(
                        author: currentUser,
                        content: contentController.text.trim(),
                        visibility: selectedVisibility,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Đăng bài ngay'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    final userService = UserFriendService();
    final postService = PostService();
    final notificationService = NotificationService();

    return StreamBuilder<UserModel?>(
      stream: userService.getUserProfileStream(currentUid),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bubble_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MiniSocial',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiSearchScreen(currentUser: currentUser),
                    ),
                  );
                },
              ),
              // NOTIFICATION ICON WITH UNREAD BADGE COUNTER
              StreamBuilder<int>(
                stream: notificationService.getUnreadCountStream(currentUser.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationScreen(
                                currentUserId: currentUser.uid,
                              ),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePostDialog(context, currentUser),
            elevation: 4,
            child: const Icon(Icons.edit_note_rounded, size: 28),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                // STORIES BAR CAROUSEL (Chỉ hiển thị Tạo tin & Bạn bè thực sự đã chấp nhận kết bạn)
                SliverToBoxAdapter(
                  child: Container(
                    height: 110,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: StreamBuilder<List<UserModel>>(
                      stream: userService.getFriendsListStream(currentUser.friendIds),
                      builder: (context, friendSnap) {
                        final acceptedFriends = friendSnap.data ?? [];
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: 1 + acceptedFriends.length,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildCreateStoryBubble(context, currentUser),
                              );
                            }
                            final friend = acceptedFriends[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildFriendStoryBubble(friend),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // CREATE POST QUICK TRIGGER BAR
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: currentUser.avatarUrl.isNotEmpty
                                ? NetworkImage(currentUser.avatarUrl)
                                : null,
                            child: currentUser.avatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCreatePostDialog(context, currentUser),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Bạn đang nghĩ gì thế, ${currentUser.displayName.split(' ').last}?',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // FEED POSTS STREAM
                StreamBuilder<List<PostModel>>(
                  stream: postService.getHomeFeedStream(
                    currentUserId: currentUser.uid,
                    currentUserFriendIds: currentUser.friendIds,
                  ),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final posts = postSnapshot.data ?? [];
                    if (posts.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'Chưa có bài viết nào.\nHãy đăng bài đầu tiên hoặc kết bạn thêm!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return PostCardWidget(
                            post: posts[index],
                            currentUser: currentUser,
                          );
                        },
                        childCount: posts.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateStoryBubble(BuildContext context, UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: user.avatarUrl.isNotEmpty
                  ? NetworkImage(user.avatarUrl)
                  : null,
              child: user.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 32)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Tạo tin',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFriendStoryBubble(UserModel friend) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: friend.avatarUrl.isNotEmpty
                ? NetworkImage(friend.avatarUrl)
                : null,
            child: friend.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 65,
          child: Text(
            friend.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Widget thẻ bài viết
class PostCardWidget extends StatelessWidget {
  final PostModel post;
  final UserModel currentUser;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.currentUser,
  });

  void _openCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentBottomSheet(
        postId: post.postId,
        postAuthorId: post.authorId,
        currentUser: currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUser.uid);
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER POST
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorAvatar.isNotEmpty
                      ? NetworkImage(post.authorAvatar)
                      : null,
                  child: post.authorAvatar.isEmpty
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            post.visibility == 'public'
                                ? Icons.public
                                : Icons.group,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            post.visibility == 'public'
                                ? 'Công khai'
                                : 'Bạn bè',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Sao chép văn bản'),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Text('Ẩn bài viết'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // CONTENT
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            // STATS ROW
            if (post.likes.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, size: 10, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likes.length} người đã thích',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Divider(height: 16),
            ] else ...[
              const Divider(height: 16),
            ],

            // ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      PostService().toggleLike(
                        postId: post.postId,
                        postAuthorId: post.authorId,
                        currentUser: currentUser,
                        isCurrentlyLiked: isLiked,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                            color: isLiked ? Colors.redAccent : Colors.grey.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Thích',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                              color: isLiked ? Colors.redAccent : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _openCommentSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.grey.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.commentCount > 0
                                ? '${post.commentCount} Bình luận'
                                : 'Bình luận',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chia sẻ bài viết!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: Colors.grey.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chia sẻ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Comment Bottom Sheet
class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final UserModel currentUser;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.currentUser,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  final _postService = PostService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    await _postService.addComment(
      postId: widget.postId,
      postAuthorId: widget.postAuthorId,
      author: widget.currentUser,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: Text(
                'Bình luận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _postService.getCommentsStream(widget.postId),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có bình luận nào.\nHãy là người đầu tiên viết bình luận!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: c.authorAvatar.isNotEmpty
                                  ? NetworkImage(c.authorAvatar)
                                  : null,
                              child: c.authorAvatar.isEmpty
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.text,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Viết bình luận...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sendComment,
                      icon: const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
