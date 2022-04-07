import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
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
  }) : super(key: key);

  @override
  State<BarterListItem> createState() => _BarterListItemState();
}

class _BarterListItemState extends State<BarterListItem> {
  get kBackgroundColor => null;
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
                          child: thumbnail.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: thumbnail,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
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
                                  errorWidget: (context, url, error) =>
                                      Container(
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
                                  product.productname ?? '',
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
                                  product.price != null
                                      ? product.price!.toStringAsFixed(2)
                                      : '0.00',
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
                right:
                    widget.likeLeftMargin ?? SizeConfig.safeBlockHorizontal * 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 27,
                    ),
                    GestureDetector(
                      onTap: widget.onLikeTapped != null
                          ? () {
                              print('LIKED: $liked');

                              widget.onLikeTapped!(liked ? 1 : -1);
                            }
                          : null,
                      child: Icon(
                        liked ? Icons.favorite : Icons.favorite_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
