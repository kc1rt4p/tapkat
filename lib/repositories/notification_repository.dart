import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/services/tapkat_encryption.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/utilities/constants.dart';

class NotificationRepository {
  final _apiService = ApiService();
  Future<bool> sendNotification({
    required String title,
    required String body,
    required String sender,
    required String receiver,
    required String barterId,
  }) async {
    final deviceid = await _getId();
    final userid = application.currentUser!.uid;
    final time = DateTime.now().millisecondsSinceEpoch;
    final response = await _apiService.post(url: 'alert', header: {
      'userid': application.currentUser!.uid,
      'deviceid': deviceid,
      'time': DateTime.now().millisecondsSinceEpoch,
      'authorization':
          TapKatEncryption.encryptMsg(userid + deviceid! + time.toString()),
    }, body: {
      'psk': psk,
      'title': title,
      'body': body,
      'sender': sender,
      'receiver': receiver,
      'barterid': barterId,
    });

    return response.data['status'] == 'SUCCESS';
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }
}
