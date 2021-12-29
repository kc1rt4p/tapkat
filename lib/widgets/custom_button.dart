import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final Function() onTap;
  final Widget? icon;
  final Color bgColor;
  final Color textColor;
  final bool removeMargin;
  const CustomButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.icon,
    this.bgColor = const Color(0xFF94D2BD),
    this.textColor = Colors.white,
    this.removeMargin = false,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        margin: !widget.removeMargin ? EdgeInsets.only(bottom: 16.0) : null,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: widget.bgColor,
          ),
        ),
        child: Center(
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
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
