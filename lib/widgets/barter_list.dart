import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';

class BarterList extends StatefulWidget {
  final List<Widget> items;
  final String label;
  final Function()? onViewAllTapped;
  final Function()? onMapBtnTapped;
  final bool removeMargin;
  final bool smallItems;
  final Widget? labelAction;
  final BuildContext context;
  final bool hideViewAll;
  final bool ownList;
  final bool loading;
  final bool removeMapBtn;

  const BarterList({
    Key? key,
    required this.items,
    required this.label,
    this.onViewAllTapped,
    this.onMapBtnTapped,
    this.removeMargin = false,
    this.smallItems = false,
    this.labelAction,
    required this.context,
    this.hideViewAll = false,
    this.ownList = false,
    this.loading = false,
    this.removeMapBtn = false,
  }) : super(key: key);

  @override
  State<BarterList> createState() => _BarterListState();
}

class _BarterListState extends State<BarterList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.removeMargin ? null : EdgeInsets.only(bottom: 10.0),
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
                Row(
                  children: [
                    widget.labelAction ??
                        Visibility(
                          visible: !widget.hideViewAll,
                          child: InkWell(
                            onTap: widget.onViewAllTapped,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(6.0, 1.0, 3.0, 1.0),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    offset: Offset(1, 1),
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('See All',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.textScaleFactor * 13,
                                      )),
                                  SizedBox(width: 5.0),
                                  Icon(
                                    Icons.chevron_right,
                                    size: SizeConfig.textScaleFactor * 17,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    Visibility(
                      visible: !widget.removeMapBtn,
                      child: Row(
                        children: [
                          SizedBox(width: 4.0),
                          InkWell(
                            onTap: widget.onMapBtnTapped,
                            child: Container(
                              padding: EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    offset: Offset(1, 1),
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.solidMap,
                                size: SizeConfig.textScaleFactor * 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.0),
                  ],
                ),
              ],
            ),
          ),
          widget.loading
              ? Container(
                  width: double.infinity,
                  height: 180.0,
                  child: SizedBox(
                    height: 50.0,
                    width: 50.0,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: kBackgroundColor,
                      ),
                    ),
                  ),
                )
              : widget.items.isNotEmpty && !widget.loading
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
                    )
                  : Container(
                      height: 80.0,
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
