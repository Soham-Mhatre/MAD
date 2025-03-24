import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../services/stock_service.dart';
import '../widgets/stock_card.dart';
import 'profile_screen.dart'; // Add this import

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StockService _stockService = StockService();
  final TextEditingController _stockController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>(); // Explicit type declaration

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            ),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          // Handle missing stocks field
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<String> stocks = List<String>.from(data['stocks'] ?? []);

          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final symbol = stocks[index];
              return FutureBuilder(
                future: _stockService.getStockData(symbol),
                builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return StockCard(symbol: symbol);
                  }

                  if (snapshot.hasError) {
                    return StockCard(
                      symbol: symbol,
                      error: 'Failed to load data',
                    );
                  }

                  final data = snapshot.data?['Global Quote'];
                  if (data == null) {
                    return StockCard(
                      symbol: symbol,
                      error: 'Invalid symbol',
                    );
                  }

                  return StockCard(
                    symbol: symbol,
                    price: data['05. price'],
                    change: data['09. change'],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddStockDialog(context, user),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, User? user) {
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _stockController,
                  decoration: InputDecoration(
                    hintText: 'Enter stock symbol (e.g., AAPL)',
                    errorText: errorMessage,
                  ),
                ),
                if (isLoading) const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: isLoading ? null : () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Add'),
                onPressed: isLoading ? null : () async {
                  final symbol = _stockController.text.trim().toUpperCase();
                  if (symbol.isEmpty || user == null) return;

                  setState(() => isLoading = true);

                  try {
                    // First ensure document exists
                    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

                    // Create document if missing
                    await userDoc.set({
                      'stocks': FieldValue.arrayUnion([symbol]),
                      'email': user.email,
                      'uid': user.uid,
                    }, SetOptions(merge: true));

                    // Then update stocks array
                    await userDoc.update({
                      'stocks': FieldValue.arrayUnion([symbol])
                    });

                    Navigator.pop(context);
                    _stockController.clear();
                  } catch (e) {
                    print("Firestore Error: $e");
                    setState(() => errorMessage = 'Failed to add stock');
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}