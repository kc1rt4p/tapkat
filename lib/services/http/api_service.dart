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
      Map<String, dynamic>? header,
      Map<String, dynamic>? body}) async {
    return await _safeFetch(() => _dio.get(url,
        queryParameters: body, options: Options(headers: header)));
  }

  Future<Response> delete({
    required String url,
    Map<String, dynamic>? header,
    Map<String, dynamic>? body,
  }) async {
    return await _safeFetch(() => _dio.delete('url'));
  }

  Future<Response> post({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic>? header,
    FormData? formData,
  }) async {
    return await _safeFetch(
      () => _dio.post(
        url,
        data: body ?? formData,
        options: Options(headers: header),
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
