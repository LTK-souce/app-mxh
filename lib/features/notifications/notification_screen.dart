import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  final String currentUserId;

  const NotificationScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              notificationService.markAllAsRead(currentUserId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đánh dấu tất cả thông báo là đã đọc.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Đã đọc tất cả'),
          ),
        ],
      ),
      body: Column(
        children: [
          // TEST NOTIFICATION BUTTON BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFEEF2FF),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bấm nút bên cạnh để kiểm tra thông báo đẩy trên điện thoại:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await notificationService.sendTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi thông báo thử nghiệm tới thiết bị!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Gửi thử'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: notificationService.getNotificationsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Bạn chưa có thông báo nào.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isLike = notif.type == 'like';
                    final timeStr = DateFormat('dd/MM HH:mm').format(notif.createdAt);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: notif.isRead ? Colors.white : const Color(0xFFEFF6FF),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: notif.senderAvatar.isNotEmpty
                                  ? NetworkImage(notif.senderAvatar)
                                  : null,
                              child: notif.senderAvatar.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isLike ? Colors.redAccent : Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Icon(
                                  isLike ? Icons.favorite : Icons.comment_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(
                                text: '${notif.senderName} ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: isLike
                                    ? 'đã thích bài viết của bạn.'
                                    : 'đã bình luận: "${notif.text}"',
                              ),
                            ],
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            timeStr,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                        trailing: !notif.isRead
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
