import 'package:flutter/material.dart';
import 'package:tapkat/utilities/size_config.dart';

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
                  borderRadius: BorderRadius.circular(15.0),
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
                      flex: 5,
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
                      flex: 3,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: SizeConfig.safeBlockVertical * 1.3,
                            horizontal: SizeConfig.safeBlockVertical),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.fontSize ??
                                    SizeConfig.textScaleFactor * 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // SizedBox(height: SizeConfig.screenHeight * 0.009),
                            Spacer(),
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
            ],
          ),
        ),
        Visibility(
          visible: !widget.hideLikeBtn,
          child: Positioned(
            top: 5,
            right: widget.likeLeftMargin ?? SizeConfig.safeBlockHorizontal * 5,
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
