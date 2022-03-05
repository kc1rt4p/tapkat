import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

InkWell buildAddItemBtn({
  required Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      height: SizeConfig.screenHeight * 0.235,
      width: SizeConfig.screenWidth * 0.40,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            offset: Offset(1, 1),
            color: Colors.grey,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          FontAwesomeIcons.plus,
          color: Colors.white,
          size: 40.0,
        ),
      ),
    ),
  );
}
