import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/logging_interceptor.dart';
import 'package:tapkat/utilities/network_interceptor.dart';

class DioConfiguration {
  Dio? _dio;
  static String? _accessToken;

  Dio init() {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseURL,
          connectTimeout: defaultConnectTimeout,
          receiveTimeout: defaultReceiveTimeout,
          contentType: 'application/json',
        ),
      );
      if (kDebugMode) {
        _dio?.interceptors.add(LoggingInterceptor());
      }
      _dio?.interceptors.add(NetworkInterceptor());
      _dio?.interceptors.add(CurlLoggerDioInterceptor(printOnSuccess: true));
    }
    return _dio!;
  }

  clear() {
    _dio?.close(force: true);
    _dio?.clear();
    _dio = null;
  }
}
