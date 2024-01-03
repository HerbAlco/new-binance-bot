import '../get_pair_price.dart';

Future<double> calculateQuantity(Map<String, dynamic> accountInfo,
    String symbol, String side, double amount) async {
  final asset = side == 'BUY'
      ? symbol.substring(0, symbol.indexOf('/'))
      : symbol.substring(0, symbol.indexOf('/'));
  final double pairPriceUSD = await getCryptoPairPrice('${asset}USDT');

  return side == 'BUY' ? (amount / pairPriceUSD) : (amount / pairPriceUSD);
}