import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getWatchlists(String userId) {
    return _firestore
        .collection('users/$userId/watchlists')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> addToWatchlist({
    required String userId,
    required String watchlistId,
    required String symbol,
    required String type,
  }) async {
    try {
      final watchlistRef = _firestore
          .collection('users/$userId/watchlists')
          .doc(watchlistId);

      await watchlistRef.update({
        'items': FieldValue.arrayUnion([{
          'symbol': symbol,
          'type': type,
          'addedAt': DateTime.now().toIso8601String(),
        }])
      });
    } catch (e) {
      print('WatchlistService Error: $e');
      rethrow;
    }
  }
}