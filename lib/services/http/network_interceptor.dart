import 'package:dio/dio.dart';
import 'package:tapkat/utilities/application.dart';
import 'package:tapkat/utilities/dialog_message.dart';

class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioError error, ErrorInterceptorHandler handler) async {
    //not need error handling for API.SYSTEM_PARAM
    if (error.type == DioErrorType.connectTimeout ||
        error.type == DioErrorType.receiveTimeout ||
        error.type == DioErrorType.sendTimeout) {
      _handleError('Server timed out');
    }

    super.onError(error, handler);
  }

  Future<void> _handleError(String message) async {
    await DialogMessage.show(
      currentContext,
      message: message,
      firstButtonClicked: () => DialogMessage.dismiss(),
    );
  }
}
