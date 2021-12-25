import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final bool ownItem;

  const ProductDetailsScreen({
    Key? key,
    required this.productId,
    this.ownItem = false,
  }) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _productBloc = ProductBloc();
  final _carouselController = CarouselController();
  int _currentCarouselIndex = 0;
  Map<String, dynamic>? mappedProductDetails;
  ProductModel? _product;

  @override
  void initState() {
    _productBloc.add(GetProductDetails(widget.productId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: BlocListener(
          bloc: _productBloc,
          listener: (context, state) {
            if (state is ProductLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetProductDetailsSuccess) {
              setState(() {
                _product = state.product;
                _product!.media!.insert(
                  0,
                  MediaPrimaryModel(
                    url: _product!.mediaPrimary!.url,
                    type: _product!.mediaPrimary!.type,
                  ),
                );
              });
            }
          },
          child: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Product Details',
                ),
                Expanded(
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          color: Colors.grey,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _product != null
                                  ? CarouselSlider(
                                      carouselController: _carouselController,
                                      options: CarouselOptions(
                                          height: SizeConfig.screenHeight * .3,
                                          enableInfiniteScroll: false,
                                          aspectRatio: 1,
                                          viewportFraction: 1,
                                          onPageChanged: (index, _) {
                                            setState(() {
                                              _currentCarouselIndex = index;
                                            });
                                          }),
                                      items: _product!.media!.map((img) {
                                        return Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: mappedProductDetails !=
                                                          null &&
                                                      mappedProductDetails![
                                                              'imgUrl']
                                                          .isEmpty
                                                  ? AssetImage(
                                                          'assets/images/image_placeholder.jpg')
                                                      as ImageProvider<Object>
                                                  : CachedNetworkImageProvider(img
                                                                  .url !=
                                                              null &&
                                                          img.url!.isNotEmpty
                                                      ? img.url!
                                                      : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg'),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : Container(
                                      height: SizeConfig.screenHeight * .3,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                              'assets/images/image_placeholder.jpg'),
                                        ),
                                      ),
                                    ),
                              _product != null
                                  ? Visibility(
                                      visible: _product!.media != null,
                                      child: Positioned(
                                        bottom: 8,
                                        child: Container(
                                          width: SizeConfig.screenWidth,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: _product!.media!
                                                .asMap()
                                                .keys
                                                .map((key) {
                                              return Container(
                                                margin:
                                                    _product!.media!.length < 5
                                                        ? EdgeInsets.only(
                                                            right: 8.0)
                                                        : null,
                                                height:
                                                    _currentCarouselIndex != key
                                                        ? 8.0
                                                        : 9.0,
                                                width:
                                                    _currentCarouselIndex != key
                                                        ? 8.0
                                                        : 9.0,
                                                decoration: BoxDecoration(
                                                  color:
                                                      _currentCarouselIndex ==
                                                              key
                                                          ? Colors.white
                                                          : Colors
                                                              .grey.shade400,
                                                  shape: BoxShape.circle,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 20.0,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      _product != null &&
                                              _product!.productname!.isNotEmpty
                                          ? _product!.productname!
                                          : '',
                                      style: Style.subtitle1
                                          .copyWith(color: Colors.black),
                                    ),
                                  ), // Item Description
                                  Container(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _product != null &&
                                                    _product!.price != null &&
                                                    _product!.currency != null
                                                ? '${_product!.currency!} ${_product!.price!.toStringAsFixed(2)}'
                                                : '',
                                            style: TextStyle(
                                              fontSize: 22.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Listed by:',
                                              style: TextStyle(
                                                fontSize: 13.0,
                                                color: Color(0xFF414141),
                                              ),
                                            ),
                                            Text(
                                              _product != null &&
                                                      _product!
                                                          .userid!.isNotEmpty
                                                  ? _product!.userid!
                                                  : '',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 16.0),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20.0, vertical: 10.0),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFBB3F03),
                                            borderRadius:
                                                BorderRadius.circular(9.0),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'View ${_product != null && _product!.userid!.isNotEmpty ? _product!.userid! : ''}\'s Store',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    child: Divider(
                                      thickness: 0.3,
                                      color: kBackgroundColor,
                                    ),
                                  ),
                                  Container(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_pin,
                                                  size: 16.0,
                                                ),
                                                Text(
                                                  _product != null &&
                                                          _product!
                                                              .address!
                                                              .address!
                                                              .isNotEmpty
                                                      ? _product!
                                                          .address!.address!
                                                      : '',
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: List.generate(5, (i) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      right:
                                                          i != 5 ? 5.0 : 0.0),
                                                  child: Icon(
                                                    i <
                                                            (_product != null &&
                                                                    _product!
                                                                            .rating !=
                                                                        null
                                                                ? _product!
                                                                    .rating!
                                                                    .round()
                                                                : 0)
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Color(0xFFFFC107),
                                                    size: 20.0,
                                                  ),
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _product != null &&
                                                  _product!.rating != null
                                              ? _product!.rating!.toString()
                                              : '0',
                                          style: TextStyle(fontSize: 16.0),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    FontAwesomeIcons.solidHeart,
                                                    color: Color(0xFF94D2BD),
                                                  ),
                                                  SizedBox(width: 5.0),
                                                  Text(_product != null &&
                                                          _product!.likes !=
                                                              null
                                                      ? _product!.likes!
                                                          .toString()
                                                      : '0'),
                                                  SizedBox(width: 20.0),
                                                  Icon(
                                                    FontAwesomeIcons.share,
                                                    color: Color(0xFF94D2BD),
                                                  ),
                                                  SizedBox(width: 20.0),
                                                  Icon(
                                                    FontAwesomeIcons
                                                        .solidCommentDots,
                                                    color: Color(0xFF94D2BD),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    child: Divider(
                                      thickness: 0.3,
                                      color: kBackgroundColor,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(bottom: 16.0),
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(bottom: 16.0),
                                          child: Text(
                                            'Product Description',
                                            style: Style.subtitle2,
                                          ),
                                        ),
                                        Container(
                                          child: Text(_product != null &&
                                                  _product!.productdesc != null
                                              ? _product!.productdesc!
                                              : '0'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !widget.ownItem,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 5.0),
                            child: CustomButton(
                              label: 'BARTER',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BarterScreen(
                                    mappedProductDetails: mappedProductDetails!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
