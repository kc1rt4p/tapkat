import 'package:flutter/material.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:timeago/timeago.dart' as timeago;

class BarterListItem extends StatefulWidget {
  final String itemName;
  final String itemPrice;
  final String imageUrl;
  final bool? liked;
  final Function()? onTapped;
  final double? width;
  final double? height;
  final double? fontSize;
  final bool hideLikeBtn;
  final DateTime? datePosted;
  final Function()? onLikeTapped;
  final double? likeLeftMargin;

  const BarterListItem({
    Key? key,
    required this.itemName,
    required this.itemPrice,
    required this.imageUrl,
    this.liked,
    this.onTapped,
    this.width,
    this.height,
    this.hideLikeBtn = false,
    this.onLikeTapped,
    this.fontSize,
    this.datePosted,
    this.likeLeftMargin,
  }) : super(key: key);

  @override
  State<BarterListItem> createState() => _BarterListItemState();
}

class _BarterListItemState extends State<BarterListItem> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Stack(
      children: [
        InkWell(
          onTap: widget.onTapped,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: widget.height ?? SizeConfig.screenHeight * 0.235,
                width: widget.width ?? SizeConfig.screenWidth * 0.40,
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
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                          color: Colors.grey,
                          image: DecorationImage(
                            image: widget.imageUrl.isNotEmpty
                                ? NetworkImage(widget.imageUrl)
                                : AssetImage(
                                        'assets/images/image_placeholder.jpg')
                                    as ImageProvider<Object>,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.fontSize ??
                                    SizeConfig.textScaleFactor * 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: SizeConfig.screenHeight * 0.007),
                            Text(
                              widget.itemPrice,
                              style: TextStyle(
                                fontSize: widget.fontSize ??
                                    SizeConfig.textScaleFactor * 12.4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              widget.datePosted != null
                  ? Text(
                      timeago.format(widget.datePosted!),
                      style: Style.subtitle2.copyWith(fontSize: 12.0),
                      textAlign: TextAlign.center,
                    )
                  : Container(),
            ],
          ),
        ),
        Visibility(
          visible: !widget.hideLikeBtn,
          child: Positioned(
            top: 5,
            left: widget.likeLeftMargin ?? SizeConfig.screenWidth * 0.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 27,
                ),
                GestureDetector(
                  onTap: widget.onLikeTapped,
                  child: Icon(
                    widget.liked != null && widget.liked!
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
