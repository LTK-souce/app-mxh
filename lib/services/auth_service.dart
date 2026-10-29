import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        throw Exception('Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      } else if (e.code == 'user-disabled') {
        throw Exception('Tài khoản này đã bị vô hiệu hóa.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Bạn đã thử đăng nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút.');
      } else {
        throw Exception('Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      }
    } catch (e) {
      throw Exception('Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          bio: 'Xin chào, tôi mới tham gia MiniSocial!',
          avatarUrl: '',
          friendIds: [],
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Tài khoản Email này đã tồn tại trên hệ thống. Vui lòng đăng nhập hoặc dùng email khác!');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ. Vui lòng kiểm tra lại!');
      } else if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu. Vui lòng nhập mật khẩu từ 6 ký tự trở lên!');
      } else {
        throw Exception('Tài khoản Email này đã tồn tại trên hệ thống. Vui lòng đăng nhập hoặc dùng email khác!');
      }
    } catch (e) {
      throw Exception('Đăng ký không thành công. Vui lòng kiểm tra lại thông tin!');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
