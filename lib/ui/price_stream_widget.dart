import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../service/service_components/calculate_decimal_place.dart';

class PriceStreamWidget extends StatefulWidget {
  final String symbol;
  final double upperLimit;
  final double lowerLimit;
  final double priceAtStart;

  const PriceStreamWidget({
    Key? key,
    required this.symbol,
    required this.upperLimit,
    required this.lowerLimit,
    required this.priceAtStart,
  }) : super(key: key);

  @override
  State<PriceStreamWidget> createState() => _PriceStreamWidgetState();
}

class _PriceStreamWidgetState extends State<PriceStreamWidget> {
  late WebSocketChannel channel;
  double currentPrice = 0.0;
  double currentUpperPrice = 0.0;
  double currentLowerPrice = 0.0;
  int decimalPlacePrice = 3;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  @override
  void didUpdateWidget(covariant PriceStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.symbol != oldWidget.symbol) {
      _disposeWebSocket();
      _initializeWebSocket();
    }
  }

  void _initializeWebSocket() {
    final url =
        'wss://stream.binance.com:9443/ws/${widget.symbol.toLowerCase()}@trade';

    channel = IOWebSocketChannel.connect(url);

    channel.stream.listen((data) {
      var jsonData = json.decode(data);
      if (mounted) {
        setState(() {
          currentPrice = double.parse(jsonData['p']);
          decimalPlacePrice = calculateDecimalPlacePrice(currentPrice);
          currentUpperPrice = widget.upperLimit - currentPrice;
          currentLowerPrice = currentPrice - widget.lowerLimit;
        });
      }
    });
  }

  void _disposeWebSocket() {
      channel.sink.close();
  }

  @override
  void dispose() {
    _disposeWebSocket();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.red,
            border: Border.all(
              color: Colors.red,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            'Horní pozice prodej: ${widget.upperLimit.toStringAsFixed(decimalPlacePrice)} (${currentUpperPrice.toStringAsFixed(decimalPlacePrice)})',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            'Aktuální cena ${widget.symbol}: ${widget.priceAtStart} (${currentPrice.toStringAsFixed(decimalPlacePrice)})',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.green,
            border: Border.all(
              color: Colors.green,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            'Dolní pozice nákup: ${widget.lowerLimit.toStringAsFixed(decimalPlacePrice)}(${currentLowerPrice.toStringAsFixed(decimalPlacePrice)})',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
