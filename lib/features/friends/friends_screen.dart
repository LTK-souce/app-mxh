import 'package:flutter/material.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_friend_service.dart';
import '../chat/chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _userService = UserFriendService();
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String currentUid) async {
    setState(() => _isSearching = true);
    final results = await _userService.searchUsers(
      currentUid,
      _searchController.text,
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserProfileStream(currentUid),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Danh bạ Bạn bè'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Bạn bè'),
                  Tab(text: 'Lời mời'),
                  Tab(text: 'Tìm bạn'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: DANH SÁCH BẠN BÈ HIỆN TẠI & NÚT CHAT
                StreamBuilder<List<UserModel>>(
                  stream: _userService.getFriendsListStream(currentUser.friendIds),
                  builder: (context, friendSnap) {
                    final friends = friendSnap.data ?? [];
                    if (friends.isEmpty) {
                      return const Center(
                        child: Text('Bạn chưa có người bạn nào trong danh bạ.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: friend.avatarUrl.isNotEmpty
                                ? NetworkImage(friend.avatarUrl)
                                : null,
                          ),
                          title: Text(friend.displayName),
                          subtitle: Text(friend.email),
                          trailing: FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    currentUser: currentUser,
                                    friendUser: friend,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Nhắn tin'),
                          ),
                        );
                      },
                    );
                  },
                ),

                // TAB 2: LỜI MỜI KẾT BẠN CHỜ DUYỆT
                StreamBuilder<List<FriendRequestModel>>(
                  stream: _userService.getIncomingRequestsStream(currentUser.uid),
                  builder: (context, reqSnap) {
                    final requests = reqSnap.data ?? [];
                    if (requests.isEmpty) {
                      return const Center(
                        child: Text('Không có lời mời kết bạn mới.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: req.senderAvatar.isNotEmpty
                                ? NetworkImage(req.senderAvatar)
                                : null,
                          ),
                          title: Text(req.senderName),
                          subtitle: const Text('Đã gửi lời mời kết bạn'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filled(
                                onPressed: () =>
                                    _userService.acceptFriendRequest(req),
                                icon: const Icon(Icons.check),
                                tooltip: 'Chấp nhận',
                              ),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                onPressed: () => _userService
                                    .rejectFriendRequest(req.requestId),
                                icon: const Icon(Icons.close),
                                tooltip: 'Từ chối',
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // TAB 3: TÌM KIẾM NGƯỜI DÙNG & GỬI KẾT BẠN
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tên hoặc email để tìm...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _performSearch(currentUser.uid),
                            child: const Text('Tìm'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                final isAlreadyFriend =
                                    currentUser.friendIds.contains(user.uid);

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: user.avatarUrl.isNotEmpty
                                        ? NetworkImage(user.avatarUrl)
                                        : null,
                                  ),
                                  title: Text(user.displayName),
                                  subtitle: Text(user.email),
                                  trailing: isAlreadyFriend
                                      ? const Chip(label: Text('Đã là bạn bè'))
                                      : OutlinedButton.icon(
                                          onPressed: () async {
                                            await _userService.sendFriendRequest(
                                              sender: currentUser,
                                              receiverId: user.uid,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Đã gửi lời mời kết bạn tới ${user.displayName}',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                              Icons.person_add_alt_1,
                                              size: 18),
                                          label: const Text('Kết bạn'),
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
