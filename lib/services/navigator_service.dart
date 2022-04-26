import 'package:flutter/material.dart';

class NavigatorService {
  static NavigatorService _instance = NavigatorService._();

  static NavigatorService get instance => _instance;

  NavigatorService._();

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  Future<dynamic> push(Widget screen, {bool fullscreenDialog = false}) {
    return _navigatorKey.currentState!.push(MaterialPageRoute(
        builder: (BuildContext context) => screen,
        fullscreenDialog: fullscreenDialog));
  }

  Future<dynamic> pushReplace(Widget route) {
    return _navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => route));
  }

  Future<dynamic> pushAndRemoveUtil(Widget route) {
    return _navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => route),
        (Route<dynamic> route) => false);
  }

  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return _navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return _navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {bool predicate = false, Object? arguments}) {
    return _navigatorKey.currentState!.pushNamedAndRemoveUntil(
        routeName, (Route<dynamic> route) => predicate,
        arguments: arguments);
  }

  void pop([result]) {
    navigatorKey.currentState!.maybePop(result);
  }

  Future<dynamic>? popUntil(
      {required String route, Map<String, dynamic>? result}) {
    if (ModalRoute.of(navigatorKey.currentContext!)?.settings.name == route) {
    } else {
      Navigator.pop(_navigatorKey.currentContext!);
    }
  }

  get canPop => _navigatorKey.currentState!.canPop();
}
