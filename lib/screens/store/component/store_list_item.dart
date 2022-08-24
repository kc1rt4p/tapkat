import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/top_store.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

class StoreListItem extends StatefulWidget {
  final TopStoreModel store;
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
                  child: widget.store.photo_url != null &&
                          widget.store.photo_url!.isNotEmpty
                      ? CachedNetworkImage(
                          progressIndicatorBuilder: (context, url, progress) {
                            return Container(
                              height: SizeConfig.screenHeight * 0.1,
                              width: SizeConfig.screenHeight * 0.14,
                              child: LoadingIndicator(
                                indicatorType: Indicator.ballScale,
                                colors: const [Colors.white],
                                strokeWidth: 1,
                              ),
                            );
                          },
                          imageUrl: widget.store.photo_url!,
                          imageBuilder: (context, imageProvider) => Container(
                            height: SizeConfig.screenHeight * 0.1,
                            width: SizeConfig.screenHeight * 0.14,
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
                          // placeholder: (context, text) => Container(
                          //   height: SizeConfig.screenHeight * 0.1,
                          //   width: SizeConfig.screenHeight * 0.12,
                          //   decoration: BoxDecoration(
                          //     borderRadius: BorderRadius.only(
                          //       topLeft: Radius.circular(20.0),
                          //       topRight: Radius.circular(20.0),
                          //     ),
                          //     color: Colors.grey,
                          //     image: DecorationImage(
                          //       image: AssetImage(
                          //           'assets/images/image_placeholder.jpg'),
                          //       fit: BoxFit.cover,
                          //     ),
                          //   ),
                          // ),
                          errorWidget: (context, url, error) => Container(
                            height: SizeConfig.screenHeight * 0.1,
                            width: SizeConfig.screenHeight * 0.14,
                            child: Icon(
                              Icons.error,
                              color: kBackgroundColor,
                            ),
                          ),
                        )
                      : Container(
                          height: SizeConfig.screenHeight * 0.1,
                          width: SizeConfig.screenHeight * 0.14,
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
              width: SizeConfig.screenHeight * 0.14,
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
                      fontSize: SizeConfig.textScaleFactor * 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // widget.store.rating != null
                  //     ? Column(
                  //         children: [
                  //           SizedBox(height: SizeConfig.screenHeight * 0.009),
                  //           Row(
                  //             children: [
                  //               RatingBar.builder(
                  //                 ignoreGestures: true,
                  //                 initialRating: widget.store.rating != null
                  //                     ? widget.store.rating!.roundToDouble()
                  //                     : 0,
                  //                 minRating: 0,
                  //                 direction: Axis.horizontal,
                  //                 allowHalfRating: true,
                  //                 itemCount: 5,
                  //                 itemSize: 10,
                  //                 tapOnlyMode: true,
                  //                 itemBuilder: (context, _) => Icon(
                  //                   Icons.star,
                  //                   color: Colors.amber,
                  //                 ),
                  //                 onRatingUpdate: (rating) {
                  //                   //
                  //                 },
                  //               ),
                  //               Text(widget.store.rating!.toStringAsFixed(1)),
                  //             ],
                  //           ),
                  //         ],
                  //       )
                  //     : Container(),
                  Visibility(
                    visible: widget.store.distance != null,
                    child: Center(
                      child: Text(
                        _getProductDistance(widget.store),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: SizeConfig.textScaleFactor * 8,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductDistance(TopStoreModel store) {
    if (store.distance == null) return '';
    final distance = store.distance;
    if (store.distance! > 1) return store.distance!.toStringAsFixed(1) + ' Km';

    final meters = store.distance! * 1000;
    if (meters < 100) return 'within 100m';
    if (meters < 300) return 'within 300m';
    return 'within 900m';
  }
}
