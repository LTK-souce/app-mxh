import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String visibility; // 'public' or 'friends'
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.visibility,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
  });

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'visibility': visibility,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    var timestamp = map['createdAt'];
    DateTime date = DateTime.now();
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }
    return PostModel(
      postId: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      visibility: map['visibility'] ?? 'public',
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      createdAt: date,
    );
  }
}
