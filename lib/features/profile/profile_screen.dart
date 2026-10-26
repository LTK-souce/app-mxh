import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/user_friend_service.dart';
import '../feed/feed_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio);
    final avatarCtrl = TextEditingController(text: user.avatarUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tự giới thiệu (Bio)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: avatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Ảnh đại diện (Avatar)',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                await UserFriendService().updateProfile(
                  uid: user.uid,
                  displayName: nameCtrl.text.trim(),
                  bio: bioCtrl.text.trim(),
                  avatarUrl: avatarCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
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

    return StreamBuilder<UserModel?>(
      stream: userService.getUserProfileStream(currentUid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Trang cá nhân',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () => AuthService().signOut(),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // COVER PHOTO & AVATAR HEADER
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                const Color(0xFF818CF8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : null,
                              child: user.avatarUrl.isEmpty
                                  ? const Icon(Icons.person, size: 46)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // USER NAME & EMAIL
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    // BIO BOX
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          user.bio.isNotEmpty
                              ? user.bio
                              : 'Chưa có tiểu sử. Hãy nhấn chỉnh sửa để cập nhật!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STATS ROW (Friends count, etc.)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Bạn bè', '${user.friendIds.length}'),
                              Container(height: 24, width: 1, color: Colors.grey.shade300),
                              StreamBuilder<List<PostModel>>(
                                stream: postService.getUserPostsStream(user.uid),
                                builder: (context, postSnap) {
                                  final count = postSnap.data?.length ?? 0;
                                  return _buildStatItem('Bài viết', '$count');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // EDIT BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditProfileDialog(context, user),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa hồ sơ cá nhân'),
                      ),
                    ),
                    const Divider(height: 32),

                    // SECTION TITLE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bài viết của tôi',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // USER POSTS STREAM
              StreamBuilder<List<PostModel>>(
                stream: postService.getUserPostsStream(user.uid),
                builder: (context, postSnap) {
                  final myPosts = postSnap.data ?? [];
                  if (myPosts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Bạn chưa đăng bài viết nào.\nHãy chia sẻ suy nghĩ của bạn trên Bảng tin!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => PostCardWidget(
                        post: myPosts[index],
                        currentUser: user,
                      ),
                      childCount: myPosts.length,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}
