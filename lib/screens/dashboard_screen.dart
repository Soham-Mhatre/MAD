import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/stock_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/stock_card.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StockService _stockService = StockService();
  final TextEditingController _stockController = TextEditingController();
  String? _selectedWatchlistId;

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final watchlistService = context.watch<WatchlistService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildWatchlistSelector(user, watchlistService),
          _buildWatchlistItems(user),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddStockDialog(context, user),
      ),
    );
  }

  Widget _buildWatchlistSelector(User? user, WatchlistService service) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: service.getWatchlists(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('No watchlists found.'),
                ElevatedButton(
                  onPressed: () => _createDefaultWatchlist(user.uid),
                  child: const Text('Create Default Watchlist'),
                ),
              ],
            ),
          );
        }

        final watchlists = snapshot.data!.docs;
        if (_selectedWatchlistId == null) {
          _selectedWatchlistId = watchlists.first.id;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedWatchlistId,
            items: watchlists.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                value: doc.id,
                child: Text(data['name'] ?? 'Unnamed List'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedWatchlistId = value),
            decoration: const InputDecoration(
              labelText: 'Select Watchlist',
              border: OutlineInputBorder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatchlistItems(User? user) {
    if (user == null || _selectedWatchlistId == null) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users/${user.uid}/watchlists')
            .doc(_selectedWatchlistId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No items in this watchlist'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

          if (items.isEmpty) {
            return const Center(child: Text('Add stocks to get started'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final symbol = item['symbol'].toString();

              return FutureBuilder<Map<String, dynamic>>(
                future: _stockService.getStockData(symbol),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return StockCard(symbol: symbol);
                  }

                  if (snapshot.hasError) {
                    return StockCard(
                      symbol: symbol,
                      error: 'Failed to load data',
                    );
                  }

                  final quote = snapshot.data?['Global Quote'];
                  if (quote == null) {
                    return StockCard(
                      symbol: symbol,
                      error: 'Invalid symbol',
                    );
                  }

                  return StockCard(
                    symbol: symbol,
                    price: quote['05. price'],
                    change: quote['09. change'],
                    type: item['type']?.toString() ?? 'stock',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createDefaultWatchlist(String userId) async {
    try {
      final watchlistRef = FirebaseFirestore.instance
          .collection('users/$userId/watchlists')
          .doc();

      await watchlistRef.set({
        'name': 'My Watchlist',
        'items': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _selectedWatchlistId = watchlistRef.id);
    } catch (e) {
      print('Error creating default watchlist: $e');
    }
  }

  void _showAddStockDialog(BuildContext context, User? user) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? errorMessage;

          return AlertDialog(
            title: const Text('Add Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _stockController,
                  decoration: InputDecoration(
                    labelText: 'Stock Symbol',
                    hintText: 'e.g., AAPL, GOOGL',
                    errorText: errorMessage,
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final symbol = _stockController.text.trim().toUpperCase();
                  if (symbol.isEmpty || user == null || _selectedWatchlistId == null) return;

                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  try {
                    final stockData = await _stockService.getStockData(symbol);
                    if (stockData['Global Quote'] == null) {
                      throw Exception('Invalid stock symbol');
                    }

                    await context.read<WatchlistService>().addToWatchlist(
                      userId: user.uid,
                      watchlistId: _selectedWatchlistId!,
                      symbol: symbol,
                      type: 'stock',
                    );

                    _stockController.clear();
                    Navigator.pop(context);
                  } catch (e) {
                    setState(() {
                      errorMessage = e.toString().replaceAll('Exception: ', '');
                    });
                    print('Add Stock Error: $e');
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}