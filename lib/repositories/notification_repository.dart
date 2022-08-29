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

  // Future<String?> _getId() async {
  //   var deviceInfo = DeviceInfoPlugin();
  //   if (defaultTargetPlatform == TargetPlatform.iOS) {
  //     // import 'dart:io'
  //     var iosDeviceInfo = await deviceInfo.iosInfo;
  //     return iosDeviceInfo.identifierForVendor; // unique ID on iOS
  //   } else {
  //     var androidDeviceInfo = await deviceInfo.androidInfo;
  //     return androidDeviceInfo.id; // unique ID on Android
  //   }
  // }
}
