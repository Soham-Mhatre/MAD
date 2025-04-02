import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document with valid timestamp
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(), // Valid in set()
        'defaultWatchlist': null,
      });

      // Create watchlist with valid timestamp
      final watchlistRef = await _firestore
          .collection('users/${result.user!.uid}/watchlists')
          .add({
        'name': 'My First Watchlist',
        'items': [],
        'sortOrder': 'manual',
        'createdAt': FieldValue.serverTimestamp(), // Valid in add()
      });

      await _firestore.collection('users').doc(result.user!.uid).update({
        'defaultWatchlist': watchlistRef.id
      });

      return result.user;
    } catch (e) {
      print("Signup Error: $e");
      return null;
    }
  }


  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userDoc = await _firestore.collection('users').doc(result.user?.uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(result.user?.uid).set({
          'uid': result.user?.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('General Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}