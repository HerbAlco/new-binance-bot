import 'package:http/http.dart' as http;
import '../components/app_strings.dart';
import 'service_components/calculate_quantity.dart';
import 'service_components/generate_signature.dart';
import 'service_components/get_account_info.dart';

Future<void> buyCryptoONMarket(
    String symbol,
    String side,
    double amount,
    ) async {
  final accountInfo = await getAccountInfo();
  if (accountInfo != null) {
    double quantity =
    await calculateQuantity(accountInfo, symbol, side, amount);

    final params = {
      'symbol': symbol.replaceAll('/', ''),
      'side': side,
      'type': 'MARKET',
      'quantity': quantity.toStringAsFixed(4),
    };

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final queryString = Uri(queryParameters: params).query;
    final signature = generateSignature(queryString, timestamp);

    await http.post(
      Uri.https('api.binance.com', '/api/v3/order'),
      headers: {'X-MBX-APIKEY': AppStrings.apiKey},
      body: {
        ...params,
        'timestamp': timestamp.toString(),
        'signature': signature
      },
    );
  }
}
