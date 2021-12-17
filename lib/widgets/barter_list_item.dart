import 'package:flutter/material.dart';

class BarterListItem extends StatefulWidget {
  final String itemName;
  final String itemPrice;
  final String imageUrl;
  final bool? liked;
  final Function()? onTapped;
  final double? width;
  final double? height;
  final bool hideLikeBtn;

  const BarterListItem({
    Key? key,
    required this.itemName,
    required this.itemPrice,
    required this.imageUrl,
    this.liked,
    this.onTapped,
    this.width = 160.0,
    this.height = 190.0,
    this.hideLikeBtn = false,
  }) : super(key: key);

  @override
  State<BarterListItem> createState() => _BarterListItemState();
}

class _BarterListItemState extends State<BarterListItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTapped,
      child: Stack(
        children: [
          Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  offset: Offset(1, 1),
                  color: Colors.grey,
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
                            : AssetImage('assets/images/image_placeholder.jpg')
                                as ImageProvider<Object>,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacer(),
                        Text(widget.itemPrice),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: !widget.hideLikeBtn,
            child: Positioned(
              top: 10,
              right: 10,
              child: Icon(
                widget.liked != null && widget.liked!
                    ? Icons.favorite
                    : Icons.favorite_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
