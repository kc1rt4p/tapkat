import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function()? onPinTapped;
  final Function()? onSearchTapped;
  final Function()? onCompleted;
  final Function(String?)? onSubmitted;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color textColor;
  final String? hintText;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    this.onPinTapped,
    this.onSearchTapped,
    this.onCompleted,
    this.onSubmitted,
    this.margin,
    this.backgroundColor,
    this.textColor = Colors.black,
    this.hintText = 'What are you looking for?',
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: widget.margin ??
                  EdgeInsets.symmetric(vertical: 3.0, horizontal: 20.0),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      onEditingComplete: widget.onCompleted,
                      onFieldSubmitted: widget.onSubmitted,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        isDense: true,
                        hintStyle:
                            TextStyle(color: widget.textColor.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  GestureDetector(
                    onTap: widget.onSubmitted != null
                        ? () {
                            widget.onSubmitted!(widget.controller.text.trim());
                            widget.controller.clearComposing();
                          }
                        : null,
                    child: Icon(
                      Icons.search,
                      color: widget.textColor,
                    ),
                  ),
                  Visibility(
                    visible: widget.onPinTapped != null,
                    child: GestureDetector(
                      onTap: widget.onPinTapped,
                      child: Icon(
                        Icons.location_pin,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
