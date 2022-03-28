import 'dart:async';

import 'package:dio/dio.dart';
import 'package:tapkat/services/http/dio_config.dart';
import 'package:tapkat/utilities/error_exception.dart';

class ApiService {
  Dio _dio = DioConfiguration().init();
  static ApiService _instance = ApiService._();
  static ApiService get instance => _instance;
  ApiService._();
  ApiService();
  Future<Response> get(
      {required String url,
      Map<String, dynamic>? headers,
      Map<String, dynamic>? body}) async {
    return await _safeFetch(
      () => _dio.get(
        url,
        queryParameters: body,
        options: Options(
          headers: headers,
        ),
      ),
    );
  }

  Future<Response> delete({
    required String url,
    Map<String, dynamic>? header,
    Map<String, dynamic>? body,
  }) async {
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
    Map<String, dynamic>? header,
  }) async {
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
    Map<String, dynamic>? header,
    Map<String, dynamic>? params,
    Function(int, int)? onSendProgress,
    FormData? formData,
  }) async {
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
}
