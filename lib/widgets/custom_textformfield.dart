import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapkat/utilities/constant_colors.dart';

class CustomTextFormField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Function()? onTap;
  final bool? isReadOnly;
  final bool isPhone;
  final Color? color;
  final Color? textColor;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool removeMargin;
  final Widget? prefix;

  const CustomTextFormField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.onTap,
    this.isReadOnly,
    this.isPhone = false,
    this.textColor,
    this.color,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.removeMargin = false,
    this.prefix,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool showError = false;
  String errorMsg = '';
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          decoration: BoxDecoration(
            color: widget.color ?? Color(0xFFE2E2E2).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: widget.color ?? kBackgroundColor,
            ),
          ),
          child: Row(
            children: [
              widget.prefix != null ? widget.prefix! : SizedBox(),
              Expanded(
                child: TextFormField(
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.maxLines,
                  readOnly: widget.isReadOnly ?? false,
                  onTap: widget.onTap,
                  controller: widget.controller,
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                  ),
                  obscureText: widget.obscureText,
                  keyboardType: widget.isPhone
                      ? TextInputType.phone
                      : widget.maxLines > 1
                          ? TextInputType.multiline
                          : widget.keyboardType,
                  decoration: InputDecoration(
                    alignLabelWithHint: widget.maxLines > 1,
                    label: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.textColor ?? Colors.white,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6.0),
                    isDense: true,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color:
                          (widget.textColor ?? Colors.white).withOpacity(0.3),
                    ),
                    prefix: widget.isPhone ? Text('+63 ') : null,
                    suffixIcon: widget.suffixIcon,
                    suffixIconConstraints: BoxConstraints(
                      minWidth: 25,
                      minHeight: 24,
                    ),
                    errorStyle: TextStyle(height: 0),
                  ),
                  validator: (val) {
                    if (widget.validator != null) {
                      final msg = widget.validator!(val);
                      if (msg != null) {
                        setState(() {
                          errorMsg = msg;
                          showError = true;
                        });
                        return '';
                      } else {
                        setState(() {
                          errorMsg = '';
                          showError = false;
                        });
                        return null;
                      }
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: showError,
          child: Text(
            errorMsg,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.red.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        widget.removeMargin ? Container() : SizedBox(height: 16.0),
      ],
    );
  }
}
