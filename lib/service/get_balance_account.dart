import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_strings.dart';
import 'service_components/generate_signature.dart';


Future<double> getCoinBalance(String coinSymbol) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final queryString = 'timestamp=$timestamp';
  final signature = generateSignature(queryString);

  final response = await http.get(
    Uri.parse('https://api.binance.com/api/v3/account?$queryString&signature=$signature'),
    headers: {
      'X-MBX-APIKEY': AppStrings.apiKey,
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final balances = data['balances'];

    for (var balance in balances) {
      if (balance['asset'] == coinSymbol) {
        return double.parse(balance['free']);
      }
    }
  }
  //TODO: try/catch při špatné odpovědi serveru
  return 0.0;
}

