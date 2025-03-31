import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class StockService {
  final String _apiKey = '4ZGWMFTHQ74P2RMZ';
  static const _maxRetries = 2;

  // Unified response processor
  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isEmpty || data.containsKey('Error Message')) {
        return {'error': 'Invalid API response'};
      }
      return data;
    }
    return {'error': 'HTTP ${response.statusCode}'};
  }

  // Generic API caller with retry logic
  Future<Map<String, dynamic>> _callAPI(String url) async {
    for (var i = 0; i < _maxRetries; i++) {
      try {
        final response = await http.get(Uri.parse(url));
        final processed = _processResponse(response);
        if (!processed.containsKey('error')) return processed;

        if (i == _maxRetries - 1) return processed;
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        if (i == _maxRetries - 1) return {'error': 'Connection failed'};
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return {'error': 'Unknown error'};
  }

  Future<Map<String, dynamic>> getStockData(String symbol) async {
    final result = await _callAPI(
        'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey'
    );

    if (result['Global Quote'] == null) {
      return {'error': 'Invalid stock symbol'};
    }
    return result;
  }

  Future<Map<String, dynamic>> getGlobalQuote(String symbol) async {
    return await _callAPI(
        'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey'
    );
  }


  Future<Map<String, dynamic>> getBatchData(List<String> symbols) async {
    return await _callAPI(
        'https://www.alphavantage.co/query?function=BATCH_STOCK_QUOTES'
            '&symbols=${symbols.join(',')}&apikey=$_apiKey'
    );
  }
  Future<Map<String, dynamic>> getTimeSeries(String symbol, String interval) async {
    final response = await http.get(
      Uri.parse(
          'https://www.alphavantage.co/query?'
              'function=TIME_SERIES_INTRADAY&'
              'symbol=$symbol&'
              'interval=${interval}min&'  // Supported values: 1, 5, 15, 30, 60
              'outputsize=compact&'
              'apikey=$_apiKey'
      ),
    );
    return _processResponse(response);
  }

  List<FlSpot> parseTimeSeries(Map<String, dynamic> data) {
    final timeSeries = data['Time Series (${data['metaData']['4. Interval']})'] as Map<String, dynamic>;
    final List<FlSpot> points = [];

    timeSeries.entries.toList().reversed.toList().asMap().forEach((index, entry) {
      final closePrice = double.parse(entry.value['4. close']);
      points.add(FlSpot(index.toDouble(), closePrice));
    });

    return points;
  }
}