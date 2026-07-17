import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'role': role,
          'name': name,
          'email': email,
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          String role = userDoc.get('role');
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);
        }
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentSnapshot> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _db.collection('users').doc(user.uid).get();
    }
    throw Exception("No authenticated user active");
  }

  Future<void> updateProfileName(String newName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({'name': newName});
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }
}
