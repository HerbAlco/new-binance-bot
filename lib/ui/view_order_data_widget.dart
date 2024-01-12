import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/order_model.dart';
import '../service/get_balance_account.dart';
import '../service/start_order_system.dart';
import 'k_chart_widget.dart';

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
  late final StreamController<DateTime> _dateTimeController =
      StreamController<DateTime>();
  late Stream<DateTime> _dateTimeStream;

  Future<void> initializeBalances() async {
    firstCoinSymbol = order.symbol.substring(0, order.symbol.indexOf('/'));
    secondCoinSymbol = order.symbol.substring(order.symbol.indexOf('/') + 1);
    firstCoinBalance = await getCoinBalance(firstCoinSymbol);
    secondCoinBalance = await getCoinBalance(secondCoinSymbol);
  }

  @override
  void initState() {
    super.initState();
    order = widget.orders.first;
    initializeBalances();

    _dateTimeStream = _dateTimeController.stream;
    _dateTimeController.addStream(
      Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        appBar: AppBar(title: const Text('Trade Bot')),
        body: ChangeNotifierProvider.value(
          value: order,
          child: Builder(
            builder: (context) {
              Order currentOrder = Provider.of<Order>(context);
              return SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              buildDropdownButton(),
                              Text(
                                'Kurz páru:  ${currentOrder.currentPrice.toString()}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: currentOrder.currentPrice > currentOrder.priceAtStart
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              StreamBuilder<DateTime>(
                                stream: _dateTimeStream,
                                builder: (context, snapshot) {
                                  // Show the current date and time
                                  if (snapshot.hasData) {
                                    return Text(
                                      DateFormat('dd.MM.yyyy HH:mm:ss')
                                          .format(snapshot.data!),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else {
                                    return const Text('Loading...');
                                  }
                                },
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                order.periodicTimer?.cancel();
                                order.spreadTimer?.cancel();
                                order.countdownTimer?.cancel();
                                cancelOpenOrders(order.clearSymbol, order.ordersID);
                                order.inBuying = false;
                                snackBar(
                                    'Obchodování bylo ukončeno.', Colors.red);
                                widget.orders.remove(order);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: const CircleBorder(),
                            ),
                            child: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        ],
                      ),
                      const KChart(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('zpět k vytvoření obchodu'),
                          ),
                        ],
                      ),
                      buildProgressBar(currentOrder.progressValue,
                          currentOrder.remainingText),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildProgressBar(double progressValue, String remainingText) {
    return Stack(
      children: [
        LinearProgressIndicator(
          backgroundColor: Colors.grey,
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

  Widget buildDropdownButton() {
    if (widget.orders.isNotEmpty) {
      final uniqueOrders = widget.orders.toSet().toList();
      if (!uniqueOrders.contains(order)) {
        order = uniqueOrders.first;
      }
      return Container(
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        child: DropdownButton<Order>(
          padding: const EdgeInsets.only(left: 15),
          value: order,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 30,
          elevation: 14,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          underline: Container(
            height: 2,
            color: Colors.transparent,
          ),
          onChanged: (Order? selectedOrder) {
            setState(() {
              if (selectedOrder != null) {
                order = selectedOrder;
                initializeBalances();
              }
            });
          },
          items: uniqueOrders.take(5).map((Order option) {
            return DropdownMenuItem<Order>(
              value: option,
              child: Text(
                option.symbol,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          borderRadius: BorderRadius.circular(15),
          dropdownColor: Colors.grey[900],
        ),
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
