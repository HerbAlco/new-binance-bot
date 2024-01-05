import 'dart:async';
import 'package:quiver/async.dart';
import '../service/get_balance_account.dart';
import '../service/get_limit_order.dart';
import '../service/get_open_order_by_symbol.dart';
import '../service/get_pair_price.dart';
import '../service/start_order_system.dart';

class Order {

  String symbol, clearSymbol, firstCoinSymbol, secondCoinSymbol;
  double currentPrice = 0.0, firstCoinBalance = 0.0, secondCoinBalance = 0.0,
      orderPriceRange, amount, upperLimit = 0.0, lowerLimit = 0.0, priceAtStart = 0.0;
  int spreadRounds, wave, spreadTime;
  bool inBuying;
  Timer? spreadTimer, periodicTimer;
  late Duration currentDuration, pollingInterval;
  CountdownTimer? countdownTimer;
  double progressValue = 0.0;
  String remainingText = '';

  Order(this.symbol, this.amount, this.spreadRounds, this.orderPriceRange, this.spreadTime)
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

  // void startPeriodicAction() {
  //   periodicTimer = Timer.periodic(pollingInterval, (timer1) async {
  //     List openOrders = await getOpenOrdersBySymbol(clearSymbol);
  //     // double firstCoinBalanceUSDT = await getCryptoPairPrice('${firstCoinSymbol}USDT') * firstCoinBalance;
  //     // double secondCoinBalanceUSDT = await getCryptoPairPrice('${secondCoinSymbol}USDT') * secondCoinBalance;
  //     // if (openOrders.isEmpty &&
  //     //     periodicTimer!.isActive &&
  //     //     (firstCoinBalanceUSDT < amount || secondCoinBalanceUSDT < amount)) {
  //     //   if (firstCoinBalanceUSDT < amount) {
  //     //     periodicTimer?.cancel();
  //     //     spreadTimer?.cancel();
  //     //     countdownTimer?.cancel();
  //     //     wave = 1;
  //     //     priceAtStart = await getCryptoPairPrice(clearSymbol);
  //     //     await startOpenOneOrder(symbol, 'BUY', amount, orderPriceRange, priceAtStart); //TODO: předělat na objednavku jednoho obchodu
  //     //     snackBar('Objednávka úspěšně vytvořena', Colors.green);
  //     //     startPeriodicAction();
  //     //     currentDuration = Duration(minutes: spreadTime);
  //     //     spreadTimer = Timer(currentDuration, () {});
  //     //     startCountdown();
  //     //     fetchData();
  //     //   } else {
  //     //     periodicTimer?.cancel();
  //     //     spreadTimer?.cancel();
  //     //     _countdownTimer?.cancel();
  //     //     wave = 1;
  //     //     priceAtStart = await getCryptoPairPrice(clearSymbol);
  //     //     await startOpenOneOrder(symbol, 'SELL', amount, orderPriceRange, priceAtStart); //TODO: předělat na objednavku jednoho obchodu
  //     //     snackBar('Objednávka úspěšně vytvořena', Colors.green);
  //     //     startPeriodicAction();
  //     //     currentDuration = Duration(minutes: spreadTime);
  //     //     spreadTimer = Timer(currentDuration, () {});
  //     //     startCountdown();
  //     //     fetchData();
  //     //   }
  //     // } else if (openOrders.length == 1 &&
  //     //     !spreadTimer!.isActive &&
  //     //     spreadRounds > wave &&
  //     //     periodicTimer!.isActive &&
  //     //     (firstCoinBalanceUSDT < amount / (wave + 1) || secondCoinBalanceUSDT < amount / (wave + 1))) {
  //     //   if (firstCoinBalanceUSDT < amount / (wave + 1)) {
  //     //     print(3);
  //     //   } else {
  //     //     print(firstCoinBalanceUSDT);
  //     //     print(secondCoinBalanceUSDT);
  //     //     print(amount / (wave + 1));
  //     //
  //     //   }
  //     // } else
  //       if (openOrders.length != 2 && periodicTimer!.isActive /*&& (firstCoinBalanceUSDT > amount && secondCoinBalanceUSDT > amount)*/) {
  //       periodicTimer?.cancel();
  //       spreadTimer?.cancel();
  //       countdownTimer?.cancel();
  //       wave = 1;
  //       priceAtStart = await getCryptoPairPrice(clearSymbol);
  //       await startOrderSystem(symbol, amount, orderPriceRange, priceAtStart);
  //       // snackBar('Objednávka úspěšně vytvořena', Colors.green); //TODO: předělat aby vracel true když bude objednávka ok nebo něco na ten styl a ukázal upozornění
  //       startPeriodicAction();
  //       currentDuration = Duration(minutes: spreadTime);
  //       spreadTimer = Timer(currentDuration, () {});
  //       countdownManager.startCountdown(currentDuration);
  //       setOrderData();
  //     } else if (!spreadTimer!.isActive &&
  //         spreadRounds > wave &&
  //         periodicTimer!.isActive /*&& (firstCoinBalanceUSDT > amount / wave && secondCoinBalanceUSDT > amount / wave)*/) {
  //       periodicTimer?.cancel();
  //       spreadTimer?.cancel();
  //       countdownTimer?.cancel();
  //       wave++;
  //       await startOrderSystem(
  //           symbol, amount / wave, orderPriceRange / wave, priceAtStart);
  //       // snackBar('Objednávka č.$wave úspěšně vytvořena', Colors.green); //TODO: předělat aby vracel true když bude objednávka ok nebo něco na ten styl a ukázal upozornění
  //       startPeriodicAction();
  //       currentDuration = Duration(minutes: wave) + currentDuration;
  //       spreadTimer = Timer(currentDuration, () {});
  //       countdownManager.startCountdown(currentDuration);
  //       setOrderData();
  //     }
  //   });
  // }

  void startPeriodicAction() {
    periodicTimer = Timer.periodic(pollingInterval, (timer1) async {
      List openOrders = await getOpenOrdersBySymbol(clearSymbol);
      if (openOrders.length != 2 && periodicTimer!.isActive) {
        periodicTimer?.cancel();
        spreadTimer?.cancel();
        countdownTimer?.cancel();
        wave = 1;
        priceAtStart = await getCryptoPairPrice(clearSymbol);
        await startOrderSystem(symbol, amount, orderPriceRange, priceAtStart);
        startPeriodicAction();
        currentDuration = Duration(minutes: spreadTime);
        spreadTimer = Timer(currentDuration, () {});
        startCountdown(currentDuration);
        setOrderData();
      } else if (!spreadTimer!.isActive && spreadRounds > wave && periodicTimer!.isActive) {
        periodicTimer?.cancel();
        spreadTimer?.cancel();
        countdownTimer?.cancel();
        wave++;
        await startOrderSystem(symbol, amount / wave, orderPriceRange / wave, priceAtStart);
        startPeriodicAction();
        currentDuration = Duration(minutes: wave) + currentDuration;
        spreadTimer = Timer(currentDuration, () {});
        startCountdown(currentDuration);
        setOrderData();
      }
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
        remainingText = '$remainingMinutes m $remainingSeconds s';
      } else {
        remainingText = '$remainingSeconds s';
      }

      progressValue = event.remaining.inSeconds / countdownDuration;
    });
  }

}
