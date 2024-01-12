import 'dart:async';

import 'cancel_order.dart';
import 'create_market_trade.dart';
import 'create_order.dart';
import 'get_balance_account.dart';
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
  String firstCoinSymbol = symbol.substring(0, symbol.indexOf('/'));
  String secondCoinSymbol = symbol.substring(symbol.indexOf('/') + 1, symbol.length);

  await cancelOpenOrders(clearSymbol, ordersID);
  final currentPrice = await getCryptoPairPrice(clearSymbol);

  double firstCoinBalance = await getCoinBalance(firstCoinSymbol);
  double secondCoinBalance = await getCoinBalance(secondCoinSymbol);

  double firstCoinBalanceUSDT = await getCryptoPairPrice('${firstCoinSymbol}USDT') * firstCoinBalance;
  double secondCoinBalanceUSDT = await getCryptoPairPrice('${secondCoinSymbol}USDT') * secondCoinBalance;

  print(firstCoinBalanceUSDT);
  print(secondCoinBalanceUSDT);

  final buyPrice = priceAtStart - (priceAtStart * orderPriceRange);
  final sellPrice = priceAtStart + (priceAtStart * orderPriceRange);

  if (currentPrice < buyPrice) {
    await buyCryptoOnMarket(symbol, 'BUY', amount);
  } else if (currentPrice > sellPrice) {
    await buyCryptoOnMarket(
        symbol, 'SELL', amount + amount * orderPriceRange * 100);
  } else if (firstCoinBalanceUSDT < amount || secondCoinBalanceUSDT < amount){
    if (firstCoinBalanceUSDT < amount) {
      ordersID.add(await createLimitOrder(symbol, 'BUY', amount, buyPrice));
    } else {
      ordersID.add(await createLimitOrder(
          symbol, 'SELL', amount + amount * orderPriceRange * 100, sellPrice));
    }
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
