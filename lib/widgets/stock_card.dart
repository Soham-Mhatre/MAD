import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TickerDetailScreen(symbol: symbol),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(),
              if (error == null) _buildPriceInfo(),
              if (error != null) _buildErrorState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          symbol,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: type == 'etf' ? Colors.blue.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: type == 'etf' ? Colors.blue.shade800 : Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    final isPositive = change?.startsWith('-') == false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          '\$$price',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              change ?? '',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            error ?? 'Error loading data',
            style: const TextStyle(color: Colors.orange),
          ),
        ],
      ),
    );
  }
}