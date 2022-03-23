import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

class StoreListItem extends StatelessWidget {
  final StoreModel store;
  const StoreListItem(this.store, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.screenHeight * 0.235,
      width: SizeConfig.screenWidth * 0.40,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: store.photo_url!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: store.photo_url!,
                    imageBuilder: (context, imageProvider) => Container(
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
                          image:
                              AssetImage('assets/images/image_placeholder.jpg'),
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
                        image:
                            AssetImage('assets/images/image_placeholder.jpg'),
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
                    store.display_name ?? '',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: SizeConfig.textScaleFactor * 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // SizedBox(height: SizeConfig.screenHeight * 0.009),
                  Spacer(),
                  Row(
                    children: [
                      RatingBar.builder(
                        ignoreGestures: true,
                        initialRating: store.rating != null
                            ? store.rating!.roundToDouble()
                            : 0,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 15,
                        tapOnlyMode: true,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          //
                        },
                      ),
                      Text(store.rating!.toStringAsFixed(1)),
                    ],
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
