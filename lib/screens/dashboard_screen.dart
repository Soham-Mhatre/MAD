import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/stock_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/stock_card.dart';
import 'profile_screen.dart';
import 'watchlist_management_screen.dart';

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
  void initState() {
    super.initState();
    _loadDefaultWatchlist();
  }

  Future<void> _loadDefaultWatchlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _selectedWatchlistId = userDoc['defaultWatchlist'];
        });
      }
    }
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
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WatchlistManagementScreen()),
            ),
          ),
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Watchlist not found'));
          }

          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final symbol = item['symbol'].toString();

              return FutureBuilder<Map<String, dynamic>>(
                future: _stockService.getStockData(symbol),
                builder: (context, snapshot) {
                  final quote = snapshot.data?['Global Quote'];
                  final error = snapshot.data?['error'];

                  return StockCard(
                    symbol: symbol,
                    price: quote?['05. price'],
                    change: quote?['09. change'],
                    error: error,
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
                    hintText: 'e.g., AAPL, MSFT',
                    errorText: errorMessage,
                    counterText: 'Uppercase letters only',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                  ],
                ),
                if (isLoading) const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final symbol = _stockController.text.trim();

                  // Enhanced validation
                  if (symbol.isEmpty) {
                    setState(() => errorMessage = 'Enter a symbol');
                    return;
                  }
                  if (symbol.length < 2 || symbol.length > 5) {
                    setState(() => errorMessage = 'Invalid symbol length');
                    return;
                  }

                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  try {
                    final stockData = await _stockService.getStockData(symbol);

                    if (stockData.containsKey('error')) {
                      throw Exception(stockData['error']);
                    }

                    await context.read<WatchlistService>().addToWatchlist(
                      userId: user!.uid,
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

  Future<void> _createDefaultWatchlist(String userId) async {
    try {
      final watchlistRef = FirebaseFirestore.instance
          .collection('users/$userId/watchlists')
          .doc();

      // Use FieldValue.serverTimestamp() for document creation
      await watchlistRef.set({
        'name': 'My Watchlist',
        'items': [],
        'createdAt': FieldValue.serverTimestamp(), // Valid in set()
      });

      setState(() => _selectedWatchlistId = watchlistRef.id);
    } catch (e) {
      print('Error creating default watchlist: $e');
    }
  }
}