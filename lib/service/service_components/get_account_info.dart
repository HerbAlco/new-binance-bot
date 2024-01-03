import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../components/app_strings.dart';

Future<Map<String, dynamic>?> getAccountInfo() async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final queryString = 'timestamp=$timestamp';

  final signature = Hmac(sha256, utf8.encode(AppStrings.secretKey))
      .convert(utf8.encode(queryString))
      .toString();

  final response = await http.get(
    Uri.parse(
        'https://api.binance.com/api/v3/account?$queryString&signature=$signature'),
    headers: {'X-MBX-APIKEY': AppStrings.apiKey},
  );

  return json.decode(response.body);
}