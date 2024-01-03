import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:new_binance_bot/components/app_strings.dart';
import 'service_components/generate_signature.dart';

Future<List<dynamic>> getOpenOrdersBySymbol(String symbol) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final params = {
    'symbol': symbol,
    'timestamp': timestamp.toString(),
  };

  final queryParams = Uri(queryParameters: params).query;

  final signature = generateSignature(queryParams, timestamp);

  final url = Uri.parse('https://api.binance.com/api/v3/openOrders?$queryParams&signature=$signature');
  final response = await http.get(url, headers: {'X-MBX-APIKEY': AppStrings.apiKey});

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as List<dynamic>;
  } else {
    throw ('Nepodařilo se načíst otevřené obchody');
  }
}