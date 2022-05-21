import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:tapkat/services/http/dio_config.dart';
import 'package:tapkat/services/tapkat_encryption.dart';
import 'package:tapkat/utilities/error_exception.dart';
import 'package:tapkat/utilities/application.dart' as application;

class ApiService {
  Dio _dio = DioConfiguration().init();
  static ApiService _instance = ApiService._();
  static ApiService get instance => _instance;
  Map<String, dynamic>? header;

  ApiService._();

  ApiService();

  _init() async {
    final deviceid = application.deviceId ?? await getDeviceId();

    final userid = application.currentUser != null
        ? application.currentUser!.uid
        : 'newuser';
    final time = DateTime.now().millisecondsSinceEpoch;

    header = {
      'deviceid': deviceid,
      'time': DateTime.now().millisecondsSinceEpoch,
      'userid': userid,
      'authorization':
          TapKatEncryption.encryptMsg(userid + deviceid! + time.toString()),
    };
  }

  Future<Response> get(
      {required String url, Map<String, dynamic>? body}) async {
    await _init();
    return await _safeFetch(
      () => _dio.get(
        url,
        queryParameters: body,
        options: Options(
          headers: header,
        ),
      ),
    );
  }

  Future<Response> delete({
    required String url,
    Map<String, dynamic>? body,
  }) async {
    await _init();
    return await _safeFetch(() => _dio.delete(
          url,
          data: body,
          options: Options(
            headers: header,
          ),
        ));
  }

  Future<Response> patch({
    required String url,
    Map<String, dynamic>? body,
  }) async {
    await _init();
    return await _safeFetch(
      () => _dio.patch(
        url,
        data: body,
        options: Options(
          headers: header,
        ),
      ),
    );
  }

  Future<Response> post({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic>? params,
    Function(int, int)? onSendProgress,
    FormData? formData,
  }) async {
    await _init();
    return await _safeFetch(
      () => _dio.post(
        url,
        data: body ?? formData,
        options: Options(
          headers: header,
          contentType:
              formData != null ? 'multipart/form-data' : 'application/json',
        ),
        onSendProgress: onSendProgress,
        queryParameters: params,
      ),
    );
  }

  Future<Response> _safeFetch(Future<Response> Function() tryFetch) async {
    var response;
    try {
      response = await tryFetch();
    } catch (e) {
      throw ErrorExceptions.handleError(e);
    }
    return response;
  }

  static Future<String?> getDeviceId() async {
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
