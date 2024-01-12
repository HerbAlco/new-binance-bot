import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiver/async.dart';
import '../service/get_balance_account.dart';
import '../service/get_limit_order.dart';
import '../service/get_open_order_by_symbol.dart';
import '../service/get_pair_price.dart';
import '../service/start_order_system.dart';

class Order extends ChangeNotifier {
  String symbol, clearSymbol, firstCoinSymbol, secondCoinSymbol;
  double currentPrice = 0.0,
      firstCoinBalance = 0.0,
      secondCoinBalance = 0.0,
      orderPriceRange,
      amount,
      upperLimit = 0.0,
      lowerLimit = 0.0,
      priceAtStart = 0.0;
  int spreadRounds, wave, spreadTime;
  bool inBuying;
  Timer? spreadTimer, periodicTimer;
  late Duration currentDuration, pollingInterval;
  CountdownTimer? countdownTimer;
  double _progressValue = 0.0;
  String _remainingText = '';
  List<int> ordersID = [];

  double get progressValue => _progressValue;
  String get remainingText => _remainingText;

  void updateProgress(double value, String text) {
    _progressValue = value;
    _remainingText = text;
    notifyListeners();
  }

  Order(this.symbol, this.amount, this.spreadRounds, this.orderPriceRange,
      this.spreadTime)
      : clearSymbol = symbol.replaceAll('/', ''),
        firstCoinSymbol = symbol.substring(0, symbol.indexOf('/')),
        secondCoinSymbol =
            symbol.substring(symbol.indexOf('/') + 1, symbol.length),
        wave = 1,
        inBuying = false;

  Future<void> setOrderData() async {
    try {
      currentDuration = Duration(minutes: spreadTime);
      pollingInterval = const Duration(seconds: 2);
      currentPrice = await getCryptoPairPrice(clearSymbol);
      firstCoinBalance = await getCoinBalance(firstCoinSymbol);
      secondCoinBalance = await getCoinBalance(secondCoinSymbol);
      upperLimit = await getOrderLimit(clearSymbol, 'SELL');
      lowerLimit = await getOrderLimit(clearSymbol, 'BUY');
      inBuying = true;
    } catch (e) {
      print('Chyba při načítání dat objednávky: $e');
    }
  }

  void startPeriodicAction() {
    void setRestart(int newWave, String symbol, double amount,
        double orderPriceRange, double priceAtStart, Duration currentDuration) async {

      spreadTimer?.cancel();
      countdownTimer?.cancel();
      await startOrderSystem(
          symbol, amount, orderPriceRange, priceAtStart, ordersID);
      startPeriodicAction();
      spreadTimer = Timer(currentDuration, () {});
      startCountdown(currentDuration);
    }

    periodicTimer = Timer.periodic(pollingInterval, (timer1) async {
      List openOrders = await getOpenOrdersBySymbol(clearSymbol);
      bool matchingOrder = false;
      for (var orderID in ordersID) {
        for (var order in openOrders){
          if (order['orderId'] == orderID){
            matchingOrder = true;
            break;
          } else {
            matchingOrder == false;
          }
        }
      }
      if (!matchingOrder && periodicTimer!.isActive) {
        periodicTimer?.cancel();
        priceAtStart = await getCryptoPairPrice(clearSymbol);
        setRestart(1, symbol, amount, orderPriceRange, priceAtStart,
            Duration(minutes: spreadTime));
      } else if (!spreadTimer!.isActive &&
          spreadRounds > wave &&
          periodicTimer!.isActive) {
        periodicTimer?.cancel();
        setRestart(wave++, symbol, amount / wave, orderPriceRange / wave,
            priceAtStart, Duration(minutes: wave) + currentDuration);
      }
      setOrderData();
    });
  }

  void startCountdown(Duration currentDuration) {
    int countdownDuration = currentDuration.inSeconds;
    const int updateInterval = 1;

    countdownTimer = CountdownTimer(
      Duration(seconds: countdownDuration),
      const Duration(seconds: updateInterval),
    );

    countdownTimer!.listen((event) {
      int remainingSeconds = event.remaining.inSeconds;

      if (remainingSeconds >= 60) {
        int remainingMinutes = remainingSeconds ~/ 60;
        remainingSeconds %= 60;
        _remainingText = '$remainingMinutes m $remainingSeconds s';
      } else {
        _remainingText = '$remainingSeconds s';
      }

      _progressValue = event.remaining.inSeconds / countdownDuration;
      updateProgress(progressValue, remainingText);
    });
  }
}
