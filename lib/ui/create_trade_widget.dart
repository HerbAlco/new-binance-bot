import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_binance_bot/service/get_pair_price.dart';
import 'package:new_binance_bot/ui/k_chart_widget.dart';

import '../components/app_strings.dart';
import '../model/order_model.dart';
import '../service/get_balance_account.dart';
import 'view_order_data_widget.dart';

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

  String symbol = AppStrings.tradablePairs[0];
  double orderPriceRange = 1;
  int spreadRounds = 1;
  double amount = 0.0;
  int spreadTime = 2;
  late String firstCoinSymbol;
  late String secondCoinSymbol;
  double firstCoinBalance = 0.0;
  double secondCoinBalance = 0.0;
  double currentPrice = 0.0;
  static final List<Order> orders = [];
  late Order order;
  late final StreamController<DateTime> _dateTimeController =
  StreamController<DateTime>();
  late Stream<DateTime> _dateTimeStream;

  @override
  void initState() {
    super.initState();
    _dateTimeStream = _dateTimeController.stream;
    _dateTimeController.addStream(
      Stream.periodic(const Duration(seconds: 1), (i) => DateTime.now()),
    );
    initializeBalances();
  }

  Future<void> initializeBalances() async {
    firstCoinSymbol = symbol.substring(0, symbol.indexOf('/'));
    secondCoinSymbol = symbol.substring(symbol.indexOf('/') + 1, symbol.length);
    firstCoinBalance = await getCoinBalance(firstCoinSymbol);
    secondCoinBalance = await getCoinBalance(secondCoinSymbol);
    currentPrice = await getCryptoPairPrice(symbol.replaceAll('/', ''));
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        buildDropdownButton(),
                        Text(
                          'Kurz páru:  ${currentPrice.toString()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                        handleBuyButtonPressed();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewOrderDataWidget(orders: orders),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const KChart(),
                const SizedBox(height: 10),
                buildBalanceContainers(),
                // TODO: dodělat aby ukazoval aktuální cenu
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
                ElevatedButton(
                  onPressed: () {
                    if (orders.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ViewOrderDataWidget(orders: orders),
                        ),
                      );
                    } else {
                      snackBar('Nemáš žádné obchody', Colors.red);
                    }
                  },
                  child: const Text('Obchodování'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdownButton() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButton<String>(
        padding: const EdgeInsets.only(left: 15),
        value: symbol,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 30,
        elevation: 14,
        style: const TextStyle(color: Colors.black, fontSize: 15),
        underline: Container(
          height: 2,
          color: Colors.transparent,
        ),
        onChanged: (String? selectedSymbol) {
          if (selectedSymbol != null) {
            setState(() {
              symbol = selectedSymbol;
              initializeBalances();
            });
          }
        },
        items: AppStrings.tradablePairs.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        borderRadius: BorderRadius.circular(15),
        dropdownColor: Colors.grey[900],
      ),
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

  void handleBuyButtonPressed() {
    setState(() {
      if (orderPriceRange * 100 < 0.1) {
        snackBar('Hodnota rozpětí je nízká, zadejte hodnotu větší než 0.1.',
            Colors.red);
      } else if (spreadRounds == 0) {
        snackBar('Počet rozpětí je nízký, zadej víc než 0.', Colors.red);
      } else {
        order =
            Order(symbol, amount, spreadRounds, orderPriceRange, spreadTime);
        orders.add(order);
        order.setOrderData();
        order.startPeriodicAction();
        snackBar('Obchodování bylo zapnuto.', Colors.green);
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
