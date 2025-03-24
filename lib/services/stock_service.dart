import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  final String _apiKey = '4ZGWMFTHQ74P2RMZ';
  static const _maxRetries = 2;

  Future<Map<String, dynamic>> getStockData(String symbol) async {
    for (var i = 0; i < _maxRetries; i++) {
      try {
        final response = await http.get(
            Uri.parse('https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey')
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['Global Quote'] == null) {
            return {'error': 'Invalid stock symbol'};
          }
          return data;
        }
      } catch (e) {
        if (i == _maxRetries - 1) return {'error': 'Connection failed'};
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return {'error': 'Unknown error'};
  }
}