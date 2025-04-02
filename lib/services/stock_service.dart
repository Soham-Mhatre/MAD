import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class StockService {
  final String _apiKey = '4DP9VMC2YY4QBBSM'; // Replace with actual key
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  Future<Map<String, dynamic>> getStockData(String symbol) async {
    // Validate symbol first
    if (symbol.isEmpty || !RegExp(r'^[A-Za-z]+$').hasMatch(symbol)) {
      return {'error': 'Invalid stock symbol'};
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.get(Uri.parse(
            'https://www.alphavantage.co/query?'
                'function=GLOBAL_QUOTE&'
                'symbol=$symbol&'
                'apikey=$_apiKey'
        )).timeout(const Duration(seconds: 10));

        // Log raw response for debugging
        print('API Response: ${response.body}');

        if (response.statusCode != 200) {
          return {'error': 'HTTP Error ${response.statusCode}'};
        }

        final data = json.decode(response.body);

        // Handle different API response cases
        if (data.containsKey('Information')) {
          return {'error': 'API Limit Reached - Try Again Later'};
        }
        if (data.containsKey('Error Message')) {
          return {'error': 'Invalid Stock Symbol'};
        }
        if (data.containsKey('Note')) {
          await Future.delayed(_retryDelay);
          continue; // Retry on API throttling
        }
        if (data['Global Quote'] == null ||
            data['Global Quote']['05. price'] == null) {
          return {'error': 'Invalid API Response'};
        }

        return data;
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          return {'error': 'Connection Failed: ${e.toString()}'};
        }
        await Future.delayed(_retryDelay);
      }
    }
    return {'error': 'Unknown Error'};
  }

  Future<Map<String, dynamic>> getTimeSeries(String symbol, String interval) async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?'
              'function=TIME_SERIES_INTRADAY&'
              'symbol=$symbol&'
              'interval=${interval}min&'
              'outputsize=compact&'
              'apikey=$_apiKey'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': 'API error ${response.statusCode}'};
    } catch (e) {
      return {'error': 'Connection failed'};
    }
  }

  List<FlSpot> parseTimeSeries(Map<String, dynamic> data) {
    try {
      final metaKey = data['Meta Data'];
      final interval = metaKey['4. Interval'] ?? '15min';
      final timeSeriesKey = 'Time Series ($interval)';

      final timeSeries = data[timeSeriesKey] as Map<String, dynamic>;
      final List<FlSpot> points = [];

      timeSeries.entries.toList().reversed.toList().asMap().forEach((index, entry) {
        final closePrice = double.tryParse(entry.value['4. close']) ?? 0.0;
        points.add(FlSpot(index.toDouble(), closePrice));
      });

      return points;
    } catch (e) {
      return [];
    }
  }
}