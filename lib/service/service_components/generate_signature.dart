import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../components/app_strings.dart';

String generateSignature(String queryString) {
  return Hmac(sha256, utf8.encode(AppStrings.secretKey))
      .convert(utf8.encode(queryString))
      .toString();
}


