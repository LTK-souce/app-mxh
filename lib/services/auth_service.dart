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
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
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
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
