import 'package:cloud_firestore/cloud_firestore.dart';

class Watchlist {
  final String id;
  final String name;
  final List<Map<String, dynamic>> items;
  final String sortOrder;
  final Timestamp createdAt;

  Watchlist({
    required this.id,
    required this.name,
    required this.items,
    required this.sortOrder,
    required this.createdAt,
  });

  factory Watchlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Watchlist(
      id: doc.id,
      name: data['name'] ?? 'Unnamed List',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      sortOrder: data['sortOrder'] ?? 'manual',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}