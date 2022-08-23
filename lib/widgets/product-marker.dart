import 'package:flutter/material.dart';
import 'package:tapkat/utilities/constant_colors.dart';

class ProductMapMarker extends StatelessWidget {
  // declare a global key and get it trough Constructor

  ProductMapMarker({
    required this.globalKeyMyWidget,
    required this.productName,
  });
  final GlobalKey globalKeyMyWidget;
  final String productName;

  @override
  Widget build(BuildContext context) {
    // wrap your widget with RepaintBoundary and
    // pass your global key to RepaintBoundary
    return RepaintBoundary(
      key: globalKeyMyWidget,
      child: Container(
        width: 155,
        height: 45,
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Colors.black,
            width: 2.0,
          ),
        ),
        child: Center(
          child: Text(
            productName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }
}
