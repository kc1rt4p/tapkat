import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:crypto/crypto.dart';
import 'package:tapkat/utilities/constants.dart';

class TapKatEncryption {
  static String encryptMsg(String msg) {
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(msg));
    return digest.toString();
  }
}
