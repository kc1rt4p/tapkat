import 'package:tapkat/models/notification.dart';
import 'package:tapkat/schemas/index.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/application.dart' as application;

class AlertRepository {
  final _apiService = ApiService();

  Future<List<NotificationModel>> getNotifications([
    String? startAfterVal,
  ]) async {
    var requestBody = {
      'msg_type': 'N01',
      'userid': application.currentUser!.uid,
      'productcount': 8,
    };

    if (startAfterVal != null) {
      requestBody.addAll({
        'startafterval': startAfterVal,
      });
    }

    final response = await _apiService.post(
      url: 'alert/${startAfterVal != null ? 'searchset' : 'searchFirst'}',
      body: requestBody,
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['notifications'] as List<dynamic>)
        .map((item) => NotificationModel.fromJson(item))
        .toList();
  }
}
