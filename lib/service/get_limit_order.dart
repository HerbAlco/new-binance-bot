import 'package:new_binance_bot/service/get_open_order_by_symbol.dart';

Future<double> getOrderLimit(String symbol, String side) async {
  try {
    final openOrders = await getOpenOrdersBySymbol(symbol);
    final price = openOrders
        .where((order) => order['side'] == side)
        .map((order) => double.parse(order['price']))
        .fold(0.0, (prev, current) => current > prev ? current : prev);
    return price;
  } catch (e) {
    return 0.0;
  }
}