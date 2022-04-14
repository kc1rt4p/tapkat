import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'dart:math';

typedef OnLikeCallBack = void Function(int);

class BarterListItem extends StatefulWidget {
  final Function()? onTapped;
  final double? width;
  final double? height;
  final double? fontSize;
  final bool hideLikeBtn;
  final double? likeLeftMargin;
  final ProductModel product;
  final OnLikeCallBack? onLikeTapped;
  final bool hideDistance;
  final String? status;

  const BarterListItem({
    Key? key,
    this.onTapped,
    this.width,
    this.height,
    this.hideLikeBtn = false,
    this.fontSize,
    this.likeLeftMargin,
    required this.product,
    this.onLikeTapped,
    this.hideDistance = false,
    this.status,
  }) : super(key: key);

  @override
  State<BarterListItem> createState() => _BarterListItemState();
}

class _BarterListItemState extends State<BarterListItem> {
  late ProductModel _product;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    LocationModel _location = application.currentUserLocation ??
        application.currentUserModel!.location!;
    return StreamBuilder<List<UserLikesRecord?>>(
      stream: queryUserLikesRecord(
        queryBuilder: (userLikesRecord) => userLikesRecord
            .where('userid', isEqualTo: application.currentUser!.uid)
            .where('productid', isEqualTo: widget.product.productid),
        singleRecord: true,
      ),
      builder: (context, snapshot) {
        bool liked = false;
        final product = widget.product;
        if (snapshot.hasData) {
          if (snapshot.data != null && snapshot.data!.isNotEmpty) {
            final _product = snapshot.data!.first;
            if (_product != null) {
              liked = true;
            }
          }
        }

        var thumbnail = '';

        if (product.mediaPrimary != null &&
            product.mediaPrimary!.url != null &&
            product.mediaPrimary!.url!.isNotEmpty)
          thumbnail = product.mediaPrimary!.url!;

        if (product.mediaPrimary != null &&
            product.mediaPrimary!.url_t != null &&
            product.mediaPrimary!.url_t!.isNotEmpty)
          thumbnail = product.mediaPrimary!.url_t!;

        if (product.mediaPrimary == null ||
            product.mediaPrimary!.url!.isEmpty &&
                product.mediaPrimary!.url_t!.isEmpty &&
                product.media != null &&
                product.media!.isNotEmpty)
          thumbnail = product.media!.first.url_t != null
              ? product.media!.first.url_t!
              : product.media!.first.url!;

        return InkWell(
          onTap: widget.onTapped,
          child: Container(
            child: Column(
              children: [
                Stack(
                  children: [
                    thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnail,
                            imageBuilder: (context, imageProvider) => Container(
                              height: widget.height ??
                                  SizeConfig.screenHeight * 0.15,
                              width: widget.height ??
                                  SizeConfig.screenHeight * 0.19,
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
                    widget.status != null
                        ? Positioned(
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 5.0),
                              color: kBackgroundColor,
                              width: widget.height ??
                                  SizeConfig.screenHeight * 0.19,
                              child: Text(
                                (widget.status ?? '').toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: SizeConfig.textScaleFactor * 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Text(''),
                    Visibility(
                      visible: !widget.hideLikeBtn,
                      child: Positioned(
                        top: 5,
                        right: 5,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: SizeConfig.textScaleFactor * 20,
                            ),
                            GestureDetector(
                              onTap: widget.onLikeTapped != null
                                  ? () {
                                      widget.onLikeTapped!(liked ? 1 : -1);
                                    }
                                  : null,
                              child: Icon(
                                liked ? Icons.favorite : Icons.favorite_outline,
                                color: liked ? Colors.red : Colors.black,
                                size: SizeConfig.textScaleFactor * 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  color: Colors.white,
                  width: widget.height ?? SizeConfig.screenHeight * 0.19,
                  padding: EdgeInsets.all(3.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        product.productname ?? '',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.fontSize ??
                              SizeConfig.textScaleFactor * 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        product.price != null
                            ? product.price!.toStringAsFixed(2)
                            : '0.00',
                        style: TextStyle(
                          fontSize: widget.fontSize ??
                              SizeConfig.textScaleFactor * 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                product.address != null &&
                        product.address!.location != null &&
                        !widget.hideDistance
                    ? Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                            '${calculateDistance(product.address!.location!.latitude, product.address!.location!.longitude, _location.latitude, _location.longitude).toStringAsFixed(1)} Km',
                            style: TextStyle(
                                fontSize: SizeConfig.textScaleFactor * 10)),
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
