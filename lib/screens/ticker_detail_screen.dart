import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/stock_service.dart';
import '../widgets/price_chart.dart';

class TickerDetailScreen extends StatefulWidget {
  final String symbol;

  const TickerDetailScreen({super.key, required this.symbol});

  @override
  State<TickerDetailScreen> createState() => _TickerDetailScreenState();
}

class _TickerDetailScreenState extends State<TickerDetailScreen> {
  final List<int> _intervalOptions = [15, 30, 60];
  int _selectedInterval = 15;
  late Future<Map<String, dynamic>> _chartData;

  @override
  void initState() {
    super.initState();
    _chartData = _fetchChartData();
  }

  Future<Map<String, dynamic>> _fetchChartData() async {
    final stockService = context.read<StockService>();
    final data = await stockService.getTimeSeries(widget.symbol, _selectedInterval.toString());
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.symbol)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIntervalSelector(),
            const SizedBox(height: 20),
            _buildChartSection(),
            const SizedBox(height: 30),
            _buildKeyMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return SegmentedButton<int>(
      segments: _intervalOptions.map((interval) {
        return ButtonSegment(
          value: interval,
          label: Text('${interval}min'),
        );
      }).toList(),
      selected: {_selectedInterval},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _selectedInterval = newSelection.first;
          _chartData = _fetchChartData();
        });
      },
    );
  }

  Widget _buildChartSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _chartData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Failed to load chart data');
        }

        final dataPoints = context.read<StockService>().parseTimeSeries(snapshot.data!);
        return PriceChart(dataPoints: dataPoints);
      },
    );
  }

  Widget _buildKeyMetrics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<StockService>().getStockData(widget.symbol),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final quote = snapshot.data!['Global Quote'];
        final price = double.parse(quote['05. price']);
        final change = double.parse(quote['09. change']);
        final percentChange = double.parse(quote['10. change percent'].replaceAll('%', ''));

        return Column(
          children: [
            _buildMetricRow('Current Price', '\$${price.toStringAsFixed(2)}'),
            _buildMetricRow('Change', '${change.toStringAsFixed(2)} (${percentChange.toStringAsFixed(2)}%)',
                color: change >= 0 ? Colors.green : Colors.red),
            _buildMetricRow('Volume', quote['06. volume']),
          ],
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(
              fontSize: 16,
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold
          )),
        ],
      ),
    );
  }
}