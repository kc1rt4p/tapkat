import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      'time': time,
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
    var stopWatch = Stopwatch();

    stopWatch.start();
    var response;
    try {
      response = await tryFetch();
    } catch (e) {
      throw ErrorExceptions.handleError(e);
    }
    stopWatch.stop();
    print(
        '====== RESPONSE TOOK: ${stopWatch.elapsed.inMilliseconds / 1000} seconds');
    return response;
  }

  static Future<String?> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; // unique ID on Android
    }
  }

  static Future<String?> getDeviceName() async {
    var deviceInfo = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.localizedModel; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.device; // unique ID on Android
    }
  }
}
