import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_strings.dart';
import 'service_components/calculate_decimal_place.dart';
import 'service_components/calculate_quantity.dart';
import 'service_components/generate_signature.dart';
import 'service_components/get_account_info.dart';

Future<int> createLimitOrder(
  String symbol,
  String side,
  double amount,
  double orderAtPrice,
) async {
  try {
    final accountInfo = await getAccountInfo();
    if (accountInfo != null) {
      double quantity =
          await calculateQuantity(accountInfo, symbol, side, amount);
      int decimalPlacePrice = calculateDecimalPlacePrice(orderAtPrice);

      final timestamp = DateTime.now().millisecondsSinceEpoch - 1000;
      final queryString =
          'symbol=${symbol.replaceAll('/', '')}&side=$side&type=LIMIT&quantity=${quantity.toStringAsFixed(4)}&price=${orderAtPrice.toStringAsFixed(decimalPlacePrice)}&timeInForce=GTC&timestamp=$timestamp';
      final signature = generateSignature(queryString);

      final response = await http.post(
        Uri.parse('https://api.binance.com/api/v3/order'),
        headers: {
          'X-MBX-APIKEY': AppStrings.apiKey,
        },
        body: {
          'symbol': symbol.replaceAll('/', ''),
          'side': side,
          'type': 'LIMIT',
          'quantity': quantity.toStringAsFixed(4),
          'price': orderAtPrice.toStringAsFixed(decimalPlacePrice),
          'timeInForce': 'GTC',
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print('objednávka úspěšně vytvořená');
        return data['orderId'];
      }
    }
  } catch (error) {
    print('Chyba při vytváření objednávky: $error');
    return 0;
  }
  return Future.value(0);
}
