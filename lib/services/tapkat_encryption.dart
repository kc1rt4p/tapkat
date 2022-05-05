import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:crypto/crypto.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TapKatEncryption {
  static String encryptMsg(String msg) {
    String key = dotenv.get('SECRETKEY', fallback: '');
    //final hmac = Hmac(sha256, utf8.encode(secretKey));
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(msg));
    return digest.toString();
  }
}
