import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../components/app_strings.dart';



Future<void> cancelOrder(String symbol, String orderId) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;

  final params = {
    'symbol': symbol,
    'orderId': orderId,
    'timestamp': timestamp.toString(),
  };

  final queryParams = Uri(queryParameters: params).query;

  final signature = Hmac(sha256, utf8.encode(AppStrings.secretKey))
      .convert(utf8.encode(queryParams))
      .toString();

  final response = await http.delete(
    Uri.https('api.binance.com', '/api/v3/order',
        {...params, 'signature': signature}),
    headers: {'X-MBX-APIKEY': AppStrings.apiKey},
  );

  if (response.statusCode == 200) {
    print('objednávka smazáná');
  } else {
    print('objednávku se nepodařilo smazat');
  }
}
