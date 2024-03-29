import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/application.dart' as application;

class NotificationRepository {
  final _apiService = ApiService();
  Future<bool> sendNotification({
    required String title,
    required String body,
    required String sender,
    required String receiver,
    required String barterId,
  }) async {
    final response = await _apiService.post(
      url: 'alert/send',
      body: {
        'title': title,
        'body': body,
        'sender': sender,
        'receiver': receiver,
        'barterid': barterId,
        'msg_type': 'N01',
        'sendername': application.currentUserModel!.display_name,
      },
    );

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
