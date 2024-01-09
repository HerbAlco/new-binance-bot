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
  int orderCondition,
) async {
  final clearSymbol = symbol.replaceAll('/', '');

  await cancelOpenOrders(clearSymbol);
  final currentPrice = await getCryptoPairPrice(clearSymbol);

  final buyPrice = priceAtStart - (priceAtStart * orderPriceRange);
  final sellPrice = priceAtStart + (priceAtStart * orderPriceRange);

  if (currentPrice < buyPrice) {
    await buyCryptoOnMarket(symbol, 'BUY', amount);
  } else if (currentPrice > sellPrice) {
    if (orderCondition <= 0){
      amount += amount * orderPriceRange * 100;
    }
    await buyCryptoOnMarket(symbol, 'SELL', amount);
  } else {
    await createLimitOrder(symbol, 'BUY', amount, buyPrice);
    if (orderCondition <= 0){
      amount += amount * orderPriceRange * 100;
    }
    await createLimitOrder(symbol, 'SELL', amount, sellPrice);
  }
}

Future<void> cancelOpenOrders(String clearSymbol) async {
  List openOrders = await getOpenOrdersBySymbol(clearSymbol);
  for (var order in openOrders) {
    await cancelOrder(clearSymbol, order['orderId'].toString());
  }
}
