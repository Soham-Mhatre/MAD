import 'package:flutter/material.dart';
import '../screens/ticker_detail_screen.dart';

class StockCard extends StatelessWidget {
  final String symbol;
  final String? price;
  final String? change;
  final String? error;
  final String type;

  const StockCard({
    super.key,
    required this.symbol,
    this.price,
    this.change,
    this.error,
    this.type = 'stock',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          if (error == null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TickerDetailScreen(symbol: symbol),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (error != null)
                    const Icon(Icons.error, color: Colors.orange, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              if (error == null) _buildPriceInfo(),
              if (error != null) _buildErrorState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo() {
    final isPositive = change != null && !change!.startsWith('-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('\$${price ?? '--'}'),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
            Text(change ?? '', style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Text(
      error ?? 'Error loading data',
      style: const TextStyle(color: Colors.orange),
    );
  }
}