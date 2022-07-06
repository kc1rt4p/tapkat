import 'package:cached_network_image/cached_network_image.dart';
import 'package:distance/distance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/application.dart' as application;

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
  final double? distance;
  final bool showRating;

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
    this.distance,
    this.showRating = true,
  }) : super(key: key);

  @override
  State<BarterListItem> createState() => _BarterListItemState();
}

class _BarterListItemState extends State<BarterListItem> {
  late ProductModel _product;

  final oCcy = new NumberFormat("#,##0.00", "en_US");

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

        if (product.media != null && product.media!.isNotEmpty) {
          for (var media in product.media!) {
            thumbnail = media.url_t ?? '';
            if (thumbnail.isNotEmpty) break;
          }
        }

        if (thumbnail.isEmpty) {
          if (product.mediaPrimary != null &&
              product.mediaPrimary!.url_t != null &&
              product.mediaPrimary!.url_t!.isNotEmpty)
            thumbnail = product.mediaPrimary!.url_t!;
        }

        return InkWell(
          onTap: widget.onTapped,
          child: Container(
            child: Column(
              children: [
                Stack(
                  children: [
                    thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            progressIndicatorBuilder: (context, url, progress) {
                              return Container(
                                height: widget.height ??
                                    SizeConfig.screenHeight * 0.13,
                                width: widget.width ??
                                    SizeConfig.screenHeight * 0.17,
                                child: LoadingIndicator(
                                  indicatorType: Indicator.ballScale,
                                  colors: const [Colors.white],
                                  strokeWidth: 1,
                                ),
                              );
                            },
                            imageUrl: thumbnail,
                            imageBuilder: (context, imageProvider) {
                              return Container(
                                height: widget.height ??
                                    SizeConfig.screenHeight * 0.13,
                                width: widget.width ??
                                    SizeConfig.screenHeight * 0.17,
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
                              );
                            },
                            // placeholder: (context, text) => Container(
                            //   height: widget.height ??
                            //       SizeConfig.screenHeight * 0.15,
                            //   width: widget.width ??
                            //       SizeConfig.screenHeight * 0.19,
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
                              height: widget.height ??
                                  SizeConfig.screenHeight * 0.13,
                              width: widget.width ??
                                  SizeConfig.screenHeight * 0.17,
                              child: Icon(
                                Icons.error,
                                color: kBackgroundColor,
                              ),
                            ),
                          )
                        : Container(
                            height:
                                widget.height ?? SizeConfig.screenHeight * 0.13,
                            width:
                                widget.width ?? SizeConfig.screenHeight * 0.17,
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
                    Visibility(
                      visible: widget.status == null &&
                          product.status == 'COMPLETED',
                      child: Positioned(
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 5.0),
                          color: kBackgroundColor,
                          width: widget.width ?? SizeConfig.screenHeight * 0.17,
                          child: Text(
                            'COMPLETED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: SizeConfig.textScaleFactor * 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    widget.status != null
                        ? Positioned(
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 5.0),
                              color: kBackgroundColor,
                              width: widget.width ??
                                  SizeConfig.screenHeight * 0.17,
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
                      visible: !widget.hideLikeBtn &&
                          widget.product.userid !=
                              application.currentUserModel!.userid,
                      child: Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                              color: kBackgroundColor,
                              borderRadius: BorderRadius.circular(30.0)),
                          child: Row(
                            children: [
                              Stack(
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
                                            widget
                                                .onLikeTapped!(liked ? 1 : -1);
                                            if (widget.product.likes != null) {
                                              widget.product.likes =
                                                  widget.product.likes! +
                                                      (liked ? -1 : 1);
                                            }
                                          }
                                        : null,
                                    child: Icon(
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_outline,
                                      color: liked ? Colors.red : Colors.black,
                                      size: SizeConfig.textScaleFactor * 17,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 3.0),
                              Text(
                                widget.product.likes != null
                                    ? widget.product.likes.toString()
                                    : '0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: SizeConfig.textScaleFactor * 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                  ),
                  width: widget.width ?? SizeConfig.screenHeight * 0.17,
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        product.productname != null
                            ? product.productname!.trim()
                            : '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.fontSize ??
                              SizeConfig.textScaleFactor * 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          product.free != null && product.free!
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.only(right: 2.0),
                                  child: Text(
                                    product.currency != null &&
                                            product.currency!.isNotEmpty
                                        ? product.currency!
                                        : application.currentUserModel!
                                                        .currency !=
                                                    null &&
                                                application.currentUserModel!
                                                    .currency!.isNotEmpty
                                            ? application
                                                .currentUserModel!.currency!
                                            : '',
                                    style: TextStyle(
                                      fontSize: widget.fontSize ??
                                          SizeConfig.textScaleFactor * 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          Text(
                            product.free != null && product.free!
                                ? 'FREE'
                                : product.price != null
                                    ? oCcy.format(product.price!)
                                    : '0.00',
                            style: TextStyle(
                              fontSize: widget.fontSize ??
                                  SizeConfig.textScaleFactor * 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          (product.address != null &&
                                      product.address!.location != null &&
                                      !widget.hideDistance) ||
                                  widget.distance != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(_getProductDistance(product),
                                      style: TextStyle(
                                          fontSize:
                                              SizeConfig.textScaleFactor * 10)),
                                )
                              : Container(),
                          Spacer(),
                          Visibility(
                            visible: product.rating != null &&
                                product.rating! > 0 &&
                                widget.showRating,
                            child: Row(
                              children: [
                                SizedBox(width: 5.0),
                                Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 15,
                                ),
                                Text(
                                  product.rating != null
                                      ? product.rating!.toStringAsFixed(1)
                                      : '0.0',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getProductDistance(ProductModel product) {
    if (product.distance == null) return '';
    final distance = product.distance;
    if (product.distance! > 1)
      return product.distance!.toStringAsFixed(1) + ' Km';

    final meters = product.distance! * 1000;
    if (meters < 100) return 'within 100m';
    if (meters < 300) return 'within 300m';
    return 'within 900m';
  }
}
