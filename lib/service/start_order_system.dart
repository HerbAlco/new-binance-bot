import 'dart:async';

import 'cancel_order.dart';
import 'create_market_trade.dart';
import 'create_order.dart';
import 'get_pair_price.dart';
import 'get_open_order_by_symbol.dart';

Future<void> startOrderSystem(
  String symbol,
  double amount,
  double orderPriceRange,
  double priceAtStart,
  List<int> ordersID,
) async {
  final clearSymbol = symbol.replaceAll('/', '');

  await cancelOpenOrders(clearSymbol, ordersID);
  final currentPrice = await getCryptoPairPrice(clearSymbol);

  final buyPrice = priceAtStart - (priceAtStart * orderPriceRange);
  final sellPrice = priceAtStart + (priceAtStart * orderPriceRange);

  if (currentPrice < buyPrice) {
    await buyCryptoOnMarket(symbol, 'BUY', amount);
  } else if (currentPrice > sellPrice) {
    await buyCryptoOnMarket(
        symbol, 'SELL', amount + amount * orderPriceRange * 100);
  } else {
    ordersID.add(await createLimitOrder(symbol, 'BUY', amount, buyPrice));
    ordersID.add(await createLimitOrder(
        symbol, 'SELL', amount + amount * orderPriceRange * 100, sellPrice));
  }
}

Future<void> cancelOpenOrders(String clearSymbol, List<int> ordersID) async {
  List openOrders = await getOpenOrdersBySymbol(clearSymbol);

  for (var order in openOrders) {
    int orderID = order['orderId'];
    if (ordersID.contains(orderID)) {
      await cancelOrder(clearSymbol, orderID.toString());
    } else {
      print('ID objednávky nenalezeno');
    }
  }
  ordersID.clear();
}
