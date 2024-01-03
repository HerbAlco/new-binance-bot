import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

Future<double> getCryptoPairPrice(String symbol) async {

  const url = 'wss://stream.binance.com:9443/ws/!ticker@arr';

  final completer = Completer<double>();
  final channel = IOWebSocketChannel.connect(url);

    channel.stream.listen(
          (data) {
        if (!completer.isCompleted) {
          final jsonData = json.decode(data);
          final tickerData = jsonData.firstWhere(
                (ticker) => ticker['s'] == symbol,
            orElse: () => null,
          );

          if (tickerData != null) {
            final price = double.parse(tickerData['c']);
            completer.complete(price);

          }
        }
      },
      cancelOnError: true,
    );
  return completer.future;
}

