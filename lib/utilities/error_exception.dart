import 'dart:io';

import 'package:dio/dio.dart';

class ErrorExceptions {
  static Map<String, String> handleError(dynamic error) {
    String errorCode = "";
    String errorDescription = "";
    if (error is String) {
      errorDescription = error;
    } else if (error is TypeError) {
      errorDescription = "Type error";
    } else if (error is FormatException) {
      errorDescription = "Parsing JSON exception.";
    } else if (error is DioError) {
      if (error is SocketException || error.error is SocketException) {
        errorDescription = _getTimeoutMessage();
      } else {
        DioError dioError = error;
        switch (dioError.type) {
          case DioErrorType.cancel:
            errorDescription = _getTimeoutMessage();
            break;
          case DioErrorType.connectTimeout:
            errorDescription = _getTimeoutMessage();
            break;
          case DioErrorType.other:
            errorDescription = _getTimeoutMessage();
            break;
          case DioErrorType.receiveTimeout:
            errorDescription = _getTimeoutMessage();
            break;
          case DioErrorType.response:
            errorCode = "404";
            errorDescription = "Not reason error message";

            break;
          case DioErrorType.sendTimeout:
            errorDescription = _getTimeoutMessage();
            break;
        }
      }
    } else if (error is Map) {
      return error as Map<String, String>;
    } else if (error is Exception) {
      if (error.toString().contains("ipify")) {
        errorDescription = _getTimeoutMessage();
      } else {
        errorDescription = _getInternalServerErrorMessage();
      }
    } else {
      errorDescription = _getInternalServerErrorMessage();
    }
    return {errorCode: errorDescription};
  }

  static String _getTimeoutMessage() {
    return "No Internet connection detected. Check your network settings and try again.";
  }

  static String _getInternalServerErrorMessage() {
    return "We're experiencing an internal server problem. Please try again later.";
  }
}
