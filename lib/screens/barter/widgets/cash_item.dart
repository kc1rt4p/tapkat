import 'package:flutter/material.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

Widget buildCashItem(num amount) {
  return InkWell(
    child: Container(
      height: SizeConfig.screenHeight * 0.231,
      width: SizeConfig.screenWidth * 0.40,
      margin: EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            offset: Offset(1, 1),
            color: Colors.grey.shade200,
            blurRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/images/cash_icon.png'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(kBackgroundColor, BlendMode.color),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: SizeConfig.textScaleFactor * 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Text(
                    amount.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: SizeConfig.textScaleFactor * 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
