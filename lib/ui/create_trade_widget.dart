import 'dart:async';

import '../components/app_strings.dart';
import 'package:flutter/material.dart';

import '../controllers/start_countdown.dart';
import '../model/order_model.dart';
import '../service/get_balance_account.dart';
import '../service/start_order_system.dart';


class CreateTradeWidget extends StatefulWidget {
  const CreateTradeWidget({super.key});
  @override
  State<CreateTradeWidget> createState() => _CreateTradeWidgetState();
}

class _CreateTradeWidgetState extends State<CreateTradeWidget> {



  //cena první objednávky
  TextEditingController amountController = TextEditingController();

  //počet zúžení
  TextEditingController spreadRoundsController = TextEditingController();

  //rozptyl od aktuální ceny k prodeji i k nákupu
  TextEditingController orderPriceRangeController = TextEditingController();

  //časovač po kterém se zúžení provede
  TextEditingController setSpreadTime = TextEditingController();

  CountdownManager countdownManager = CountdownManager();
  String symbol = AppStrings.tradablePairs[0];
  double orderPriceRange = 1;
  int spreadRounds = 1;
  double amount = 0.0;
  int spreadTime = 2;
  late String firstCoinSymbol;
  late String secondCoinSymbol;
  late double firstCoinBalance = 0.0;
  late double secondCoinBalance = 0.0;
  final List<Order> orders = [];
  late Order order;

  @override
  void initState() {
    super.initState();
    initializeBalances();
  }

  Future<void> initializeBalances() async {
    firstCoinSymbol = symbol.substring(0, symbol.indexOf('/'));
    secondCoinSymbol = symbol.substring(symbol.indexOf('/') + 1, symbol.length);
    firstCoinBalance = await getCoinBalance(firstCoinSymbol);
    secondCoinBalance = await getCoinBalance(secondCoinSymbol);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        appBar: AppBar(title: const Text('Trade Bot')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildAutocomplete(),
                const SizedBox(height: 10),
                buildBalanceContainers(),
                // const SizedBox(height: 10),
                // PriceStreamWidget(
                //   symbol: order.symbol.replaceAll('/', ''),
                //   upperLimit: order.upperLimit,
                //   lowerLimit: order.lowerLimit,
                //   priceAtStart: order.priceAtStart,
                // ), TODO: předělat aby ukazoval aktuální cenu
                const SizedBox(height: 10),
                buildTextField(
                  controller: amountController,
                  labelText: 'Kolik USD chceš investovat: ',
                  onSubmitted: (value) {
                    setState(() {
                      amount = double.tryParse(value) ?? 0.0;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      amount = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildTextField(
                  controller: spreadRoundsController,
                  labelText: 'Kolikrát chceš rozdělit rozpětí: ',
                  onSubmitted: (value) {
                    setState(() {
                      spreadRounds = int.tryParse(value) ?? 0;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      spreadRounds = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildTextField(
                  controller: orderPriceRangeController,
                  labelText: 'Nastav % rozptylu: ',
                  onSubmitted: (value) {
                    setState(() {
                      orderPriceRange =
                          (double.tryParse(value.replaceAll(',', '.')) ?? 0.0) /
                              100;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      orderPriceRange =
                          (double.tryParse(value.replaceAll(',', '.')) ?? 0.0) /
                              100;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildTextField(
                  controller: setSpreadTime,
                  labelText: 'Nastav časovač: ',
                  onSubmitted: (value) {
                    setState(() {
                      spreadTime = int.tryParse(value) ?? 0;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      spreadTime = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                buildButtonsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAutocomplete() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: symbol),
      optionsBuilder: (TextEditingValue textValue) {
        return AppStrings.tradablePairs
            .where((String value) =>
            value.toLowerCase().startsWith(textValue.text.toLowerCase()))
            .toList();
      },
      onSelected: (String selectedValue) {
        setState(() {
          symbol = selectedValue;
        });
      },
    );
  }

  Widget buildBalanceContainers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildBalanceContainer('Peněženka $firstCoinSymbol:', firstCoinBalance),
        buildBalanceContainer(
            'Peněženka $secondCoinSymbol:', secondCoinBalance),
      ],
    );
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

  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    void Function(String)? onSubmitted,
    void Function(String)? onChanged,
  }) {
    return SizedBox(
      width: 300,
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.black,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white),
          suffixStyle: const TextStyle(color: Colors.grey),
        ),
        cursorColor: Colors.white,
      ),
    );
  }

  //TODO: předělat do view_order_data_widget
  // Widget buildProgressBar() {
  //   return Stack(
  //     children: [
  //       LinearProgressIndicator(
  //         backgroundColor: Colors.white,
  //         color: Colors.green,
  //         borderRadius: BorderRadius.circular(15),
  //         value: order.progressValue,
  //         minHeight: 20,
  //       ),
  //       Positioned.fill(
  //         child: Align(
  //           alignment: Alignment.center,
  //           child: Text(
  //             order.remainingText,
  //             style: const TextStyle(
  //               color: Colors.black,
  //               fontSize: 16,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            handleBuyButtonPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Otevřít nákup'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              order.periodicTimer?.cancel();
              order.spreadTimer?.cancel();
              order.countdownTimer?.cancel();
              cancelOpenOrders(order.clearSymbol);
              snackBar('Obchodování bylo ukončeno.', Colors.red);
              order.setOrderData();
            });
          },
          style: ElevatedButton.styleFrom(),
          child: const Text('Otevřený prodej'),
        ),
      ],
    );
  }

  void handleBuyButtonPressed() {
    setState(() {
      if (orderPriceRange * 100 < 0.1) {
        snackBar('Hodnota rozpětí je nízká, zadejte hodnotu větší než 0.1.',
            Colors.red);
      } else if (spreadRounds == 0) {
        snackBar('Počet rozpětí je nízký, zadej víc než 0.', Colors.red);
      } else if (orders.isEmpty || !order.inBuying){
        order = Order(symbol, amount, spreadRounds, orderPriceRange, spreadTime);
        orders.add(order);
        order.setOrderData();
        order.startPeriodicAction();
        snackBar('Obchodování bylo zapnuto.', Colors.green);
      } else {
        order.periodicTimer?.cancel();
        order.spreadTimer?.cancel();
        order.countdownTimer?.cancel();
        cancelOpenOrders(order.clearSymbol);
        snackBar('Obchodování bylo ukončeno.', Colors.red);
        order.setOrderData();
      }
    });
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
