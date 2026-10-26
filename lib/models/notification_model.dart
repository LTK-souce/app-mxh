import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type; // 'like' or 'comment'
  final String postId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.postId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type,
      'postId': postId,
      'text': text,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    var timestamp = map['createdAt'];
    DateTime date = DateTime.now();
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }
    return NotificationModel(
      notificationId: documentId,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'] ?? '',
      type: map['type'] ?? 'like',
      postId: map['postId'] ?? '',
      text: map['text'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: date,
    );
  }
}
