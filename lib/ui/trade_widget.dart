import 'dart:async';

import 'package:new_binance_bot/ui/price_stream_widget.dart';
import '../components/app_strings.dart';
import 'package:flutter/material.dart';

import '../controllers/start_countdown.dart';
import '../model/order_model.dart';
import '../service/start_order_system.dart';


class TradeWidget extends StatefulWidget {
  const TradeWidget({super.key});
  @override
  State<TradeWidget> createState() => _TradeWidgetState();
}

class _TradeWidgetState extends State<TradeWidget> {

  //symbol pro objednávku
  TextEditingController symbolController = TextEditingController();

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

  final List<Order> orders = List.empty();

  @override
  void initState() {
    super.initState();
    symbolController.text = symbol;
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
                const SizedBox(height: 10),
                PriceStreamWidget(
                  symbol: order.symbol.replaceAll('/', ''),
                  upperLimit: order.upperLimit,
                  lowerLimit: order.lowerLimit,
                  priceAtStart: order.priceAtStart,
                ),
                const SizedBox(height: 10),
                buildTextField(
                  controller: amountController,
                  labelText: 'Kolik USD chceš investovat: ',
                  result: '(${(order.amount / order.wave).toStringAsFixed(2)})',
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
                  result: '(${order.wave})',
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
                  result:
                  '(${((order.orderPriceRange / order.wave) * 100).toStringAsFixed(2)}%)',
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
                  result: '(${order.currentDuration.inMinutes} min)',
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
                buildProgressBar(),
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
        buildBalanceContainer('Peněženka ${order.firstCoinSymbol}:', order.firstCoinBalance),
        buildBalanceContainer(
            'Peněženka ${order.secondCoinSymbol}:', order.secondCoinBalance),
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
    required String result,
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
          suffixText: result,
          suffixStyle: const TextStyle(color: Colors.grey),
        ),
        cursorColor: Colors.white,
      ),
    );
  }

  Widget buildProgressBar() {
    return Stack(
      children: [
        LinearProgressIndicator(
          backgroundColor: Colors.white,
          color: Colors.green,
          borderRadius: BorderRadius.circular(15),
          value: order.progressValue,
          minHeight: 20,
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Text(
              order.remainingText,
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

  Widget buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () {
            handleBuyButtonPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: order.inBuying ? Colors.redAccent : Colors.green,
          ),
          child: order.inBuying
              ? const Text('Zavřít nákup')
              : const Text('Otevřít nákup'),
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
      } else {
        order.inBuying = order.inBuying == true ? false : true;
      }
      if (order.inBuying) {
        order.currentDuration = Duration(minutes: spreadTime);
        order.spreadTimer = Timer(order.currentDuration, () {});
        order.startPeriodicAction();
        order = Order(symbolController.text, amount, spreadRounds, orderPriceRange, spreadTime);
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
