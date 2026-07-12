import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    } else {
      throw Exception("User data not found in Firestore");
    }
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    
    final userModel = UserModel(
      uid: user.uid,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
      isAnonymous: false,
      dailyChatCount: 0,
      lastChatReset: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return await getUserData(credential.user!.uid);
  }

  Future<UserModel> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user!;
    
    final userModel = UserModel(
      uid: user.uid,
      displayName: 'Guest User',
      email: null,
      createdAt: DateTime.now(),
      isAnonymous: true,
      dailyChatCount: 0,
      lastChatReset: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> signInWithGoogle() async {
    // Standard mock/placeholder structure for Google Sign-In as it requires specific developer config.
    // In production, we'd use GoogleSignIn().signIn() and credential flows.
    throw UnimplementedError("Google Sign-In needs SHA configuration in Firebase Console.");
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': name,
      });
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> upgradeAnonymousAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);
      await user.updateDisplayName(displayName);
      
      await _firestore.collection('users').doc(user.uid).update({
        'email': email,
        'displayName': displayName,
        'isAnonymous': false,
      });
    }
  }
}
