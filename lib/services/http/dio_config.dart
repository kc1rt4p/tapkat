import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/logging_interceptor.dart';
import 'package:tapkat/utilities/network_interceptor.dart';

class DioConfiguration {
  Dio? _dio;

  Dio init() {
    if (_dio == null) {
      _dio = Dio(BaseOptions(
          connectTimeout: defaultConnectTimeout,
          receiveTimeout: defaultReceiveTimeout,
          headers: {'Content-Type': 'application/json; charset=UTF-8'}));
      if (kDebugMode) {
        _dio?.interceptors.add(LoggingInterceptor());
      }
      _dio?.interceptors.add(NetworkInterceptor());
    }
    return _dio!;
  }

  clear() {
    _dio?.close(force: true);
    _dio?.clear();
    _dio = null;
  }
}
