import 'package:flutter/material.dart';
import 'package:tapkat/utilities/constant_colors.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function()? onPinTapped;
  final Function()? onSearchTapped;
  final Function()? onCompleted;
  final Function(String?)? onSubmitted;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    this.onPinTapped,
    this.onSearchTapped,
    this.onCompleted,
    this.onSubmitted,
    this.margin,
    this.backgroundColor,
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
                  EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      onEditingComplete: widget.onCompleted,
                      onFieldSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'What are you looking for?',
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
                      color: kBackgroundColor,
                    ),
                  ),
                  Visibility(
                    visible: widget.onPinTapped != null,
                    child: GestureDetector(
                      onTap: widget.onPinTapped,
                      child: Icon(
                        Icons.location_pin,
                        color: kBackgroundColor,
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
