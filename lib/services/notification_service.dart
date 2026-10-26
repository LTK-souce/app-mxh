import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _realtimeSubscription;
  bool _isInitialized = false;

  /// Khởi tạo hệ thống Thông báo Local và xin quyền trên Android 13+
  Future<void> initializeLocalNotifications() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Xin quyền hiển thị thông báo trên Android 13+ (API 33+)
    await androidImplementation?.requestNotificationsPermission();

    const androidChannel = AndroidNotificationChannel(
      'minisocial_channel_v2',
      'MiniSocial Notifications',
      description: 'Kênh nhận thông báo lượt thích và bình luận MiniSocial',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation?.createNotificationChannel(androidChannel);

    _isInitialized = true;
  }

  /// Hiển thị thông báo ngay lập tức trên thanh trạng thái điện thoại
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initializeLocalNotifications();

    const androidDetails = AndroidNotificationDetails(
      'minisocial_channel_v2',
      'MiniSocial Notifications',
      channelDescription: 'Kênh nhận thông báo lượt thích và bình luận MiniSocial',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Bắn thông báo thử nghiệm trực tiếp xuống thiết bị
  Future<void> sendTestNotification() async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🔔 Thông báo thử nghiệm MiniSocial',
      body: 'Ứng dụng đã kích hoạt thành công tính năng nhận thông báo!',
    );
  }

  /// Tạo bản ghi thông báo trên Firestore và phát thông báo
  Future<void> sendNotification({
    required String recipientId,
    required UserModel sender,
    required String type, // 'like' hoặc 'comment'
    required String postId,
    required String text,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      recipientId: recipientId,
      senderId: sender.uid,
      senderName: sender.displayName,
      senderAvatar: sender.avatarUrl,
      type: type,
      postId: postId,
      text: text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('notifications').add(notification.toMap());

    // Nếu gửi cho chính mình hoặc đang thử nghiệm, phát thông báo trực tiếp
    if (recipientId == sender.uid) {
      String title = type == 'like' ? '❤️ Lượt thích mới' : '💬 Bình luận mới';
      String body = type == 'like'
          ? '${sender.displayName} đã thích bài viết của bạn!'
          : '${sender.displayName} đã bình luận: "$text"';

      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
      );
    }
  }

  /// Lắng nghe Firestore theo thời gian thực để phát thông báo khi có bản ghi mới
  void listenToRealtimeNotifications(String currentUserId) {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final senderName = data['senderName'] ?? 'Một người dùng';
            final type = data['type'] ?? 'like';
            final text = data['text'] ?? '';

            String title = 'MiniSocial';
            String body = '';

            if (type == 'like') {
              title = '❤️ Lượt thích mới';
              body = '$senderName đã thích bài viết của bạn!';
            } else if (type == 'comment') {
              title = '💬 Bình luận mới';
              body = '$senderName đã bình luận: "$text"';
            }

            showLocalNotification(
              id: change.doc.id.hashCode,
              title: title,
              body: body,
            );
          }
        }
      }
    });
  }

  /// Lấy Stream danh sách thông báo của người dùng
  Stream<List<NotificationModel>> getNotificationsStream(String recipientId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Lấy Stream số lượng thông báo chưa đọc
  Stream<int> getUnreadCountStream(String recipientId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead(String recipientId) async {
    final query = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  void stopListening() {
    _realtimeSubscription?.cancel();
  }
}
