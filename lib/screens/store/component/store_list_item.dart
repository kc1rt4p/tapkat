import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

class StoreListItem extends StatefulWidget {
  final StoreModel store;
  final Function()? onLikeTapped;
  final Function()? onTap;
  final bool? liked;
  final bool removeLike;
  const StoreListItem(
    this.store, {
    Key? key,
    this.onLikeTapped,
    this.liked = false,
    this.removeLike = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<StoreListItem> createState() => _StoreListItemState();
}

class _StoreListItemState extends State<StoreListItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  child: widget.store.photo_url!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.store.photo_url!,
                          imageBuilder: (context, imageProvider) => Container(
                            height: SizeConfig.screenHeight * 0.15,
                            width: SizeConfig.screenHeight * 0.19,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                topRight: Radius.circular(20.0),
                              ),
                              color: Colors.grey,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                alignment: FractionalOffset.center,
                                image: imageProvider,
                              ),
                            ),
                          ),
                          placeholder: (context, text) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                topRight: Radius.circular(20.0),
                              ),
                              color: Colors.grey,
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/image_placeholder.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150.0,
                            child: Icon(
                              Icons.error,
                              color: kBackgroundColor,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(20.0),
                            ),
                            color: Colors.grey,
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/image_placeholder.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            Container(
              color: Colors.white,
              width: SizeConfig.screenHeight * 0.17,
              padding: EdgeInsets.all(3.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.store.display_name ?? '',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: SizeConfig.textScaleFactor * 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  widget.store.rating != null
                      ? Column(
                          children: [
                            SizedBox(height: SizeConfig.screenHeight * 0.009),
                            Row(
                              children: [
                                RatingBar.builder(
                                  ignoreGestures: true,
                                  initialRating: widget.store.rating != null
                                      ? widget.store.rating!.roundToDouble()
                                      : 0,
                                  minRating: 0,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize: 15,
                                  tapOnlyMode: true,
                                  itemPadding:
                                      EdgeInsets.symmetric(horizontal: 4.0),
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    //
                                  },
                                ),
                                Text(widget.store.rating!.toStringAsFixed(1)),
                              ],
                            ),
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
