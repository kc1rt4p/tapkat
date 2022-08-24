import 'package:flutter/material.dart';
import 'package:tapkat/utilities/size_config.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final Function() onTap;
  final Widget? icon;
  final Color bgColor;
  final Color textColor;
  final bool removeMargin;
  final bool enabled;
  final double? fontSize;
  final double? width;
  const CustomButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.icon,
    this.bgColor = const Color(0xFF005F73),
    this.textColor = Colors.white,
    this.removeMargin = false,
    this.enabled = true,
    this.fontSize,
    this.width,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled ? widget.onTap : null,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        margin: !widget.removeMargin ? EdgeInsets.only(bottom: 12.0) : null,
        width: widget.width ?? double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 10.0,
        ),
        decoration: BoxDecoration(
          color: widget.enabled ? widget.bgColor : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: widget.enabled ? widget.bgColor : Colors.grey.shade400,
          ),
        ),
        child: Center(
          child: FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon != null
                    ? Row(
                        children: [
                          widget.icon!,
                          SizedBox(width: 10.0),
                        ],
                      )
                    : Container(),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize:
                        widget.fontSize ?? SizeConfig.textScaleFactor * 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
