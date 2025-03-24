import 'package:flutter/material.dart';

class StockCard extends StatelessWidget {
  final String symbol;
  final String? price;
  final String? change;
  final String? error;

  const StockCard({
    required this.symbol,
    this.price,
    this.change,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(symbol),
        subtitle: error != null
            ? Text(error!, style: TextStyle(color: Colors.red))
            : Text('Price: \$${price ?? 'Loading...'}'),
        trailing: error == null
            ? Text(
          change ?? '',
          style: TextStyle(
            color: (change?.startsWith('-') ?? false)
                ? Colors.red
                : Colors.green,
          ),
        )
            : Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}