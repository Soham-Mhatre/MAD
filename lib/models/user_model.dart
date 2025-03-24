import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final List<String> stocks;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.stocks,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      stocks: List<String>.from(data['stocks'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}