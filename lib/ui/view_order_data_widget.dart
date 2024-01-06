import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/order_model.dart';
import '../service/get_balance_account.dart';
import '../service/start_order_system.dart';
import 'price_stream_widget.dart';

class ViewOrderDataWidget extends StatefulWidget {
  final List<Order> orders;

  const ViewOrderDataWidget({Key? key, required this.orders}) : super(key: key);

  @override
  State<ViewOrderDataWidget> createState() => _ViewOrderDataWidgetState();
}

class _ViewOrderDataWidgetState extends State<ViewOrderDataWidget> {
  late String firstCoinSymbol;
  late String secondCoinSymbol;
  double firstCoinBalance = 0.0;
  double secondCoinBalance = 0.0;
  late Order order;

  @override
  void initState() {
    super.initState();
    order = widget.orders.first;
    initializeBalances();
  }

  Future<void> initializeBalances() async {
    firstCoinSymbol = order.symbol
        .substring(0, order.symbol.indexOf('/'));
    secondCoinSymbol = order.symbol
        .substring(order.symbol.indexOf('/') + 1);
    firstCoinBalance = await getCoinBalance(firstCoinSymbol);
    secondCoinBalance = await getCoinBalance(secondCoinSymbol);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        appBar: AppBar(title: const Text('Trade Bot')),
        body: ChangeNotifierProvider.value(
          value: order,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildAutocomplete(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildBalanceContainer('Peněženka $firstCoinSymbol:',
                          order.firstCoinBalance),
                      buildBalanceContainer('Peněženka $secondCoinSymbol:',
                          order.secondCoinBalance),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PriceStreamWidget(
                    symbol: order.symbol.replaceAll('/', ''),
                    upperLimit: order.upperLimit,
                    lowerLimit: order.lowerLimit,
                    priceAtStart: order.priceAtStart,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            order.periodicTimer?.cancel();
                            order.spreadTimer?.cancel();
                            order.countdownTimer?.cancel();
                            cancelOpenOrders(order.clearSymbol);
                            order.inBuying = false;
                            snackBar('Obchodování bylo ukončeno.', Colors.red);
                            widget.orders.remove(order);
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Zavřít obchodování'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(),
                        child: const Text('Vytvoření obchodu'),
                      ),
                    ],
                  ),
                  buildProgressBar(order.progressValue, order.remainingText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProgressBar(double progressValue, String remainingText) {
    return Stack(
      children: [
        LinearProgressIndicator(
          backgroundColor: Colors.white,
          color: Colors.green,
          borderRadius: BorderRadius.circular(15),
          value: progressValue,
          minHeight: 20,
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Text(
              remainingText,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAutocomplete() {
    if (widget.orders.isNotEmpty) {
      return Autocomplete<Order>(
        initialValue: TextEditingValue(text: widget.orders[0].symbol),
        optionsBuilder: (TextEditingValue textValue) {
          return (widget.orders)
              .where((Order order) => order.symbol
                  .toLowerCase()
                  .contains(textValue.text.toLowerCase()))
              .toList();
        },
        onSelected: (Order selectedOrder) {
          setState(() {
            order = selectedOrder;
            initializeBalances();
          });
        },
        displayStringForOption: (Order option) => option.symbol,
      );
    } else {
      return const Text('Seznam objednávek je prázdný');
    }
  }

  Widget buildBalanceContainer(String label, double balance) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(8),
      child: Text(
        '$label ${balance.toStringAsFixed(7)}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  void snackBar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
