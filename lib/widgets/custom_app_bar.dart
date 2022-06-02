import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';

class CustomAppBar extends StatefulWidget {
  final String? label;
  final Function()? onBackTapped;
  final Widget? child;
  final bool hideBack;
  final Widget? action;
  final Widget? leading;
  final bool centerTitle;

  const CustomAppBar({
    Key? key,
    this.label,
    this.onBackTapped,
    this.child,
    this.hideBack = false,
    this.action,
    this.leading,
    this.centerTitle = false,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(11.0, SizeConfig.paddingTop, 16.0, 0),
      height: kToolbarHeight + SizeConfig.paddingTop,
      width: SizeConfig.screenWidth,
      decoration: BoxDecoration(
        color: kBackgroundColor,
      ),
      child: widget.child ??
          Row(
            mainAxisAlignment: widget.hideBack
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            children: [
              widget.hideBack
                  ? widget.leading ?? Container()
                  : GestureDetector(
                      onTap:
                          widget.onBackTapped ?? () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(5.0),
                        child: FaIcon(
                          FontAwesomeIcons.chevronLeft,
                          color: Colors.white,
                        ),
                      ),
                    ),
              widget.label != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        widget.hideBack
                            ? Container()
                            : SizedBox(
                                width: 16.0,
                              ),
                        Center(
                          child: Text(
                            widget.label!,
                            style: Style.subtitle1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              widget.action ?? Container(),
            ],
          ),
    );
  }
}
