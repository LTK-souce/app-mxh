import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost({
    required UserModel author,
    required String content,
    required String visibility,
  }) async {
    final post = PostModel(
      postId: '',
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      content: content,
      visibility: visibility,
      likes: [],
      commentCount: 0,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  Stream<List<PostModel>> getHomeFeedStream({
    required String currentUserId,
    required List<String> currentUserFriendIds,
  }) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allPosts = snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data(), doc.id);
      }).toList();

      return allPosts.where((post) {
        if (post.visibility == 'public') return true;
        if (post.authorId == currentUserId) return true;
        if (currentUserFriendIds.contains(post.authorId)) return true;
        return false;
      }).toList();
    });
  }

  Stream<List<PostModel>> getUserPostsStream(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data(), doc.id);
      }).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  Future<void> toggleLike({
    required String postId,
    required String postAuthorId,
    required UserModel currentUser,
    required bool isCurrentlyLiked,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);
    if (isCurrentlyLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Bắn thông báo Like
      await NotificationService().sendNotification(
        recipientId: postAuthorId,
        sender: currentUser,
        type: 'like',
        postId: postId,
        text: 'đã thích bài viết của bạn',
      );
    }
  }

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addComment({
    required String postId,
    required String postAuthorId,
    required UserModel author,
    required String text,
  }) async {
    final comment = CommentModel(
      commentId: '',
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) return;

      int currentCount = postSnap.data()?['commentCount'] ?? 0;
      transaction.update(postRef, {'commentCount': currentCount + 1});

      final newCommentRef = postRef.collection('comments').doc();
      transaction.set(newCommentRef, comment.toMap());
    });

    // Bắn thông báo Comment
    await NotificationService().sendNotification(
      recipientId: postAuthorId,
      sender: author,
      type: 'comment',
      postId: postId,
      text: text,
    );
  }
}
