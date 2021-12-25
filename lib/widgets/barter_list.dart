import 'package:flutter/material.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/style.dart';

class BarterList extends StatefulWidget {
  final List<Widget> items;
  final String label;
  final Function()? onViewAllTapped;
  final bool removeMargin;
  final bool smallItems;
  final Widget? labelAction;
  final BuildContext context;
  final bool hideViewAll;
  final bool ownList;

  const BarterList({
    Key? key,
    required this.items,
    required this.label,
    this.onViewAllTapped,
    this.removeMargin = false,
    this.smallItems = false,
    this.labelAction,
    required this.context,
    this.hideViewAll = false,
    this.ownList = false,
  }) : super(key: key);

  @override
  State<BarterList> createState() => _BarterListState();
}

class _BarterListState extends State<BarterList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.removeMargin ? null : EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Container(
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: Style.subtitle2.copyWith(
                      color: kBackgroundColor, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                widget.labelAction ??
                    Visibility(
                      visible: !widget.hideViewAll,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(16.0, 2.0, 10.0, 2.0),
                        decoration: BoxDecoration(
                          color: Color(0xFF94D2BD),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: GestureDetector(
                          onTap: widget.onViewAllTapped,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('See All'),
                              SizedBox(width: 5.0),
                              Icon(
                                Icons.chevron_right,
                                size: 20.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          widget.items.isNotEmpty
              ? Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 10.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.items
                          .map(
                            (item) => Container(
                              margin: EdgeInsets.only(right: 8.0),
                              padding: EdgeInsets.all(2.0),
                              child: item,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // CarouselSlider(
                  //   options: CarouselOptions(
                  //     viewportFraction: widget.smallItems ? 0.42 : 0.50,
                  //     autoPlay: false,
                  //     enableInfiniteScroll: true,
                  //     initialPage: 0,
                  //     disableCenter: true,
                  //   ),
                  //   items: widget.items,
                  // ),
                )
              : Container(
                  height: 100.0,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'No items found',
                      style: Style.subtitle2.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
