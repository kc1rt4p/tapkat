import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/application.dart' as application;

final oCcy = new NumberFormat("#,##0.00", "en_US");

Widget buildCashItem(num amount) {
  return InkWell(
    child: Container(
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
          Container(
            height: SizeConfig.screenHeight * 0.13,
            width: SizeConfig.screenHeight * 0.17,
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
          Container(
            padding: EdgeInsets.all(5.0),
            width: SizeConfig.screenHeight * 0.17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: SizeConfig.textScaleFactor * 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${application.currentUserModel!.currency ?? 'PHP'} ${oCcy.format(amount)}',
                  style: TextStyle(
                    fontSize: SizeConfig.textScaleFactor * 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
