import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

enum ApiCallType {
  GET,
  POST,
  DELETE,
}

enum BodyType {
  NONE,
  JSON,
  TEXT,
  X_WWW_FORM_URL_ENCODED,
}

class ApiCallRecord extends Equatable {
  ApiCallRecord(this.callName, this.apiUrl, this.headers, this.params,
      this.body, this.bodyType);
  final String? callName;
  final String? apiUrl;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? params;
  final String? body;
  final BodyType? bodyType;

  @override
  List<Object?> get props =>
      [callName, apiUrl, headers, params, body, bodyType];
}

class ApiManager {
  ApiManager._();

  // Cache that will ensure identical calls are not repeatedly made.
  static Map<ApiCallRecord, dynamic> _apiCache = {};

  static ApiManager? _instance;
  static ApiManager get instance => _instance ??= ApiManager._();

  // If your API calls need authentication, populate this field once
  // the user has authenticated. Alter this as needed.
  static String? _accessToken;

  // You may want to call this if, for example, you make a change to the
  // database and no longer want the cached result of a call that may
  // have changed.
  static void clearCache(String callName) => _apiCache.keys
      .toSet()
      .forEach((k) => k.callName == callName ? _apiCache.remove(k) : null);

  static Map<String, String> toStringMap(Map<String, dynamic> map) =>
      map.map((key, value) => MapEntry(key, value.toString()));

  static String asQueryParams(Map<String, dynamic> map) =>
      map.entries.map((e) => "${e.key}=${e.value}").join('&');

  static Future<dynamic> urlRequest(
    ApiCallType callType,
    String apiUrl,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
    bool returnResponse,
  ) async {
    if (params != null && params.isNotEmpty) {
      final lastUriPart = apiUrl.split('/').last;
      final needsParamSpecifier = !lastUriPart.contains('?');
      apiUrl =
          '$apiUrl${needsParamSpecifier ? '?' : ''}${asQueryParams(params)}';
    }
    final makeRequest = callType == ApiCallType.GET ? http.get : http.delete;
    final response = await makeRequest(Uri.parse(apiUrl),
        headers: toStringMap(headers ?? {}));
    var jsonResponse;
    try {
      jsonResponse = json.decode(response.body);
    } catch (_) {
      // response may be empty, or invalid JSON.
    }
    return returnResponse ? jsonResponse ?? {} : null;
  }

  static Future<dynamic> postRequest(
      String apiUrl,
      Map<String, dynamic>? headers,
      Map<String, dynamic>? params,
      String? body,
      BodyType? bodyType,
      [bool returnResponse = false]) async {
    final postBody = createPostBody(headers ?? {}, params, body, bodyType);
    final response = await http.post(Uri.parse(apiUrl),
        headers: toStringMap(headers ?? {}), body: postBody);
    var jsonResponse;
    try {
      jsonResponse = json.decode(response.body);
    } catch (_) {
      // response may be empty, or invalid JSON.
    }
    return returnResponse ? jsonResponse ?? {} : null;
  }

  static dynamic createPostBody(
    Map<String, dynamic> headers,
    Map<String, dynamic>? params,
    String? body,
    BodyType? bodyType,
  ) {
    String? contentType;
    dynamic postBody;
    switch (bodyType ?? BodyType.JSON) {
      case BodyType.NONE:
        break;
      case BodyType.JSON:
        contentType = 'application/json';
        postBody = body;
        break;
      case BodyType.TEXT:
        contentType = 'text/plain';
        postBody = body;
        break;
      case BodyType.X_WWW_FORM_URL_ENCODED:
        contentType = 'application/x-www-form-urlencoded';
        postBody = toStringMap(params ?? {});
    }
    if (contentType != null) {
      headers.addAll({'Content-Type': contentType});
    }
    return postBody;
  }

  Future<dynamic> makeApiCall({
    String? callName,
    String? apiUrl,
    ApiCallType? callType,
    Map<String, dynamic>? headers = const {},
    Map<String, dynamic>? params = const {},
    String? body,
    BodyType? bodyType,
    bool? returnResponse,
    bool? cache = false,
  }) async {
    final callRecord = ApiCallRecord(
      callName,
      apiUrl,
      headers,
      params,
      body,
      bodyType,
    );
    // Modify for your specific needs if this differs from your API.
    if (_accessToken != null) {
      headers!.addAll({
        'Token $_accessToken': HttpHeaders.authorizationHeader,
      });
    }
    if (!apiUrl!.startsWith('http')) {
      apiUrl = 'https://$apiUrl';
    }

    // If we've already made this exact call before and caching is on,
    // return the cached result.
    if (cache! && _apiCache.containsKey(callRecord)) {
      return _apiCache[callRecord];
    }

    var result;
    switch (callType!) {
      case ApiCallType.GET:
      case ApiCallType.DELETE:
        result = await urlRequest(
            callType, apiUrl, headers, params, returnResponse ?? false);
        break;
      case ApiCallType.POST:
        result = await postRequest(
            apiUrl, headers, params, body, bodyType, returnResponse ?? false);
        break;
    }

    // If caching is on, cache the result (if present).
    if (cache && result != null) {
      _apiCache[callRecord] = result;
    }

    return result;
  }
}
