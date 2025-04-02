import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add this method to resolve getWatchlists error
  Stream<QuerySnapshot> getWatchlists(String userId) {
    return _firestore
        .collection('users/$userId/watchlists')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addToWatchlist({
    required String userId,
    required String watchlistId,
    required String symbol,
    required String type,
  }) async {
    try {
      final docRef = _firestore
          .collection('users/$userId/watchlists')
          .doc(watchlistId);

      // Use DateTime for array items
      final newItem = {
        'symbol': symbol.toUpperCase(),
        'type': type,
        'addedAt': DateTime.now().toIso8601String(), // String timestamp
      };

      await docRef.update({
        'items': FieldValue.arrayUnion([newItem])
      });
    } catch (e) {
      print('WatchlistService Error: $e');
      rethrow;
    }
  }
}