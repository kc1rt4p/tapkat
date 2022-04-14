import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_edit_screen.dart';
import 'package:tapkat/screens/product/product_ratings_screen.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tapkat/utilities/application.dart' as application;

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
  int _currentCarouselIndex = 0;
  Map<String, dynamic>? mappedProductDetails;
  ProductModel? _product;
  User? _user;
  UserModel? _userModel;

  LatLng? googleMapsCenter;
  late LocationModel _location;

  final _refreshController = RefreshController();

  @override
  void initState() {
    _productBloc.add(GetProductDetails(widget.productId));

    super.initState();
    _user = application.currentUser;
    _userModel = application.currentUserModel;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    LocationModel _location = application.currentUserLocation ??
        application.currentUserModel!.location!;
    return Scaffold(
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        barrierEnabled: false,
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) async {
                print('----- current details state: $state');
                // if (state is ProductLoading) {
                //   ProgressHUD.of(context)!.show();
                // } else {
                //   ProgressHUD.of(context)!.dismiss();
                // }

                if (state is DeleteProductSuccess) {
                  await DialogMessage.show(context,
                      message: 'The product has been deleted.');

                  Navigator.pop(context, true);
                }

                if (state is GetProductDetailsSuccess) {
                  _refreshController.refreshCompleted();
                  setState(() {
                    _product = state.product;
                  });
                  print('===== product status: ${_product!.toJson()}');
                }

                if (state is AddLikeSuccess ||
                    state is AddRatingSuccess ||
                    state is UnlikeSuccess) {
                  _productBloc.add(GetProductDetails(widget.productId));
                }
              },
            ),
            // BlocListener(
            //   bloc: _authBloc,
            //   listener: (context, state) {
            //     print('current auth state: $state');
            //     if (state is GetCurrentUsersuccess) {
            //       setState(() {
            //         _user = state.user;
            //         _userModel = state.userModel;
            //       });
            //       _productBloc.add(GetProductDetails(widget.productId));
            //     }
            //   },
            // ),
          ],
          child: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Product Details',
                ),
                Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    onRefresh: () =>
                        _productBloc.add(GetProductDetails(widget.productId)),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: Colors.grey,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _product != null
                                    ? _buildPhotos()
                                    : Container(
                                        height: SizeConfig.screenHeight * .35,
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
                                                      _product!.media!.length <
                                                              5
                                                          ? EdgeInsets.only(
                                                              right: 8.0)
                                                          : null,
                                                  height:
                                                      _currentCarouselIndex !=
                                                              key
                                                          ? 8.0
                                                          : 9.0,
                                                  width:
                                                      _currentCarouselIndex !=
                                                              key
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
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _product != null &&
                                                      _product!.productname!
                                                          .isNotEmpty
                                                  ? _product!.productname!
                                                  : '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Style.subtitle1.copyWith(
                                                  color: Colors.black,
                                                  fontSize: SizeConfig
                                                          .textScaleFactor *
                                                      18),
                                            ),
                                          ),
                                          Visibility(
                                            visible: _product != null &&
                                                _product!.status != null &&
                                                _product!.status!
                                                        .toLowerCase() !=
                                                    'available',
                                            child: Text(
                                              '(${_product != null && _product!.status != null && _product!.status!.toLowerCase() != 'available' ? _product!.status!.toUpperCase() : 'AVAILABLE'})',
                                              style: Style.fieldText.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    SizeConfig.textScaleFactor *
                                                        15,
                                                color: Colors.red.shade400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ), // Item Description
                                    Container(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              _product != null &&
                                                      _product!.price != null &&
                                                      _product!.currency != null
                                                  ? '${_product!.currency!} ${_product!.price!.toStringAsFixed(2)}'
                                                  : '',
                                              style: TextStyle(
                                                color: kBackgroundColor,
                                                fontFamily: 'Poppins',
                                                fontSize:
                                                    SizeConfig.textScaleFactor *
                                                        18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16.0),
                                          Visibility(
                                            visible: !widget.ownItem,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: ((context) =>
                                                        StoreScreen(
                                                          userId:
                                                              _product!.userid!,
                                                          userName:
                                                              _product!.userid!,
                                                        )),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin:
                                                    EdgeInsets.only(left: 8.0),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 20.0,
                                                    vertical: 10.0),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFBB3F03),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          9.0),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'View Store',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12.0,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
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
                                    InkWell(
                                      onTap: _onMapViewTapped,
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 6.0),
                                        child: Row(
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
                                                          .isNotEmpty &&
                                                      _product!.address!.city !=
                                                          null &&
                                                      _product!.address!
                                                              .country !=
                                                          null
                                                  ? '${_product!.address!.city}, ${_product!.address!.country}'
                                                  : '',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Spacer(),
                                            _product != null &&
                                                    _product!.address != null &&
                                                    _product!.address!
                                                            .location !=
                                                        null
                                                ? Text(
                                                    '${calculateDistance(_product!.address!.location!.latitude, _product!.address!.location!.longitude, _location.latitude, _location.longitude).toStringAsFixed(2)}km away',
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: _product != null
                                                ? InkWell(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              ProductRatingsScreen(
                                                                  product:
                                                                      _product!)),
                                                    ),
                                                    child: Container(
                                                      child: Row(
                                                        children: [
                                                          RatingBar.builder(
                                                            ignoreGestures:
                                                                true,
                                                            initialRating: _product!
                                                                        .rating !=
                                                                    null
                                                                ? _product!
                                                                    .rating!
                                                                    .roundToDouble()
                                                                : 0,
                                                            minRating: 0,
                                                            direction:
                                                                Axis.horizontal,
                                                            allowHalfRating:
                                                                true,
                                                            itemCount: 5,
                                                            itemSize: SizeConfig
                                                                    .textScaleFactor *
                                                                13,
                                                            tapOnlyMode: true,
                                                            itemPadding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        4.0),
                                                            itemBuilder:
                                                                (context, _) =>
                                                                    Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            onRatingUpdate:
                                                                (rating) {},
                                                            // onRatingUpdate:
                                                            //     (rating) {
                                                            //   if (_product!
                                                            //               .userid !=
                                                            //           _user!
                                                            //               .uid &&
                                                            //       _product!
                                                            //               .acquired_by ==
                                                            //           _user!
                                                            //               .uid) {
                                                            //     _productBloc.add(
                                                            //         AddRating(
                                                            //             _product!,
                                                            //             rating));
                                                            //   }
                                                            // },
                                                          ),
                                                          SizedBox(width: 8.0),
                                                          Text(
                                                            _product != null &&
                                                                    _product!
                                                                            .rating !=
                                                                        null
                                                                ? _product!
                                                                    .rating!
                                                                    .toStringAsFixed(
                                                                        1)
                                                                : '0',
                                                            style: TextStyle(
                                                                fontSize: 16.0),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Container(),
                                          ),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    _user != null &&
                                                            _product != null
                                                        ? StreamBuilder<
                                                            List<
                                                                UserLikesRecord?>>(
                                                            stream:
                                                                queryUserLikesRecord(
                                                              queryBuilder: (userLikesRecord) => userLikesRecord
                                                                  .where(
                                                                      'userid',
                                                                      isEqualTo:
                                                                          _user!
                                                                              .uid)
                                                                  .where(
                                                                      'productid',
                                                                      isEqualTo:
                                                                          _product!
                                                                              .productid),
                                                              singleRecord:
                                                                  true,
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              print(
                                                                  '=== snapshot= ${snapshot.data}');
                                                              bool liked =
                                                                  false;
                                                              if (snapshot
                                                                  .hasData) {
                                                                if (snapshot.data != null) if (snapshot
                                                                    .data!
                                                                    .isNotEmpty)
                                                                  liked = true;
                                                                else
                                                                  liked = false;
                                                              }

                                                              return GestureDetector(
                                                                onTap: () {
                                                                  if (_product!
                                                                          .userid !=
                                                                      application
                                                                          .currentUser!
                                                                          .uid) {
                                                                    if (liked) {
                                                                      _productBloc
                                                                          .add(
                                                                        Unlike(
                                                                            _product!),
                                                                      );
                                                                    } else {
                                                                      _productBloc.add(
                                                                          AddLike(
                                                                              _product!));
                                                                    }
                                                                  }
                                                                },
                                                                child: Icon(
                                                                  liked
                                                                      ? FontAwesomeIcons
                                                                          .solidHeart
                                                                      : FontAwesomeIcons
                                                                          .heart,
                                                                  color: Color(
                                                                      0xFF94D2BD),
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : Container(),
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
                                        thickness: 0.6,
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
                                            margin:
                                                EdgeInsets.only(bottom: 16.0),
                                            child: Text(
                                              'Product Description',
                                              style: Style.subtitle2,
                                            ),
                                          ),
                                          Container(
                                            child: Text(_product != null &&
                                                    _product!.productdesc !=
                                                        null
                                                ? _product!.productdesc!
                                                : '0'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _product != null
                                        ? Text(
                                            'Last updated ${timeago.format(_product!.updated_time ?? DateTime.now())}.')
                                        : Container(),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      child: Divider(
                                        thickness: 0.6,
                                        color: kBackgroundColor,
                                      ),
                                    ),
                                    _product != null &&
                                            _product!.tradeFor != null
                                        ? Container(
                                            margin:
                                                EdgeInsets.only(bottom: 10.0),
                                            child: Row(
                                              children: [
                                                Text('Trade for: '),
                                                Expanded(
                                                  child: Wrap(
                                                    children: [
                                                      ...List.generate(
                                                          _product!.tradeFor!
                                                              .length, (index) {
                                                        if (index <
                                                            _product!.tradeFor!
                                                                    .length -
                                                                1)
                                                          return Text(
                                                              '${_product!.tradeFor![index]}, ');
                                                        else
                                                          return Text(
                                                              '${_product!.tradeFor![index]}');
                                                      })
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text(''),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _product != null
                              ? _product!.userid != application.currentUser!.uid
                                  ? Visibility(
                                      visible:
                                          (_product!.status!.toLowerCase() !=
                                                  'sold' &&
                                              _product!.status!.toLowerCase() !=
                                                  'reserved'),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20.0, vertical: 5),
                                        child: CustomButton(
                                          label: 'BARTER',
                                          onTap: () {
                                            print(
                                                '=====-==== ${_product!.toJson()}');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BarterScreen(
                                                        product: _product!),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: CustomButton(
                                              label: 'DELETE',
                                              icon: Icon(
                                                FontAwesomeIcons.trash,
                                                color: Colors.white,
                                                size: 16.0,
                                              ),
                                              bgColor: Colors.red,
                                              removeMargin: true,
                                              onTap: _onDeleteTapped,
                                            ),
                                          ),
                                          SizedBox(width: 20.0),
                                          Expanded(
                                            child: CustomButton(
                                              label: 'EDIT',
                                              removeMargin: true,
                                              bgColor: kBackgroundColor,
                                              icon: Icon(
                                                FontAwesomeIcons.solidEdit,
                                                color: Colors.white,
                                                size: 16.0,
                                              ),
                                              onTap: _onEditTapped,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                              : Container(),
                        ],
                      ),
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

  _onMapViewTapped() {
    showGeneralDialog(
        context: context,
        pageBuilder: (context, _, __) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 30.0,
            ),
            backgroundColor: Colors.white,
            child: Container(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map,
                          color: kBackgroundColor,
                        ),
                        SizedBox(width: 16.0),
                        Text(
                          _product!.productname!,
                          style: TextStyle(
                            color: kBackgroundColor,
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TapkatGoogleMap(
                      showLocation: true,
                      initialZoom: 14,
                      onCameraIdle: (latLng) => googleMapsCenter = latLng,
                      initialLocation: LatLng(
                          _product!.address != null &&
                                  _product!.address!.location != null
                              ? _product!.address!.location!.latitude!
                                  .toDouble()
                              : 0.00,
                          _product!.address != null &&
                                  _product!.address!.location != null
                              ? _product!.address!.location!.longitude!
                                  .toDouble()
                              : 0.00),
                      onMapCreated: (controller) {
                        //
                      },
                      markers: [
                        TapkatMarker(
                            _product!.productid!,
                            LatLng(
                              _product!.address != null &&
                                      _product!.address!.location != null
                                  ? _product!.address!.location!.latitude!
                                      .toDouble()
                                  : 0.00,
                              _product!.address != null &&
                                      _product!.address!.location != null
                                  ? _product!.address!.location!.longitude!
                                      .toDouble()
                                  : 0.00,
                            ),
                            () => _onMarkerTapped(_product!),
                            _product),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildPhotos() {
    if (_product == null) return Container();

    if (_product!.mediaPrimary != null &&
        _product!.mediaPrimary!.url != null &&
        _product!.mediaPrimary!.url!.isNotEmpty) {
      if (_product!.media != null &&
              _product!.media!.isNotEmpty &&
              _product!.media!.length > 1 ||
          _product!.media!.length == 0) {
        if (!_product!.media!
            .any((media) => media.url == _product!.mediaPrimary!.url)) {
          _product!.media!.insert(
              0,
              MediaPrimaryModel(
                url: _product!.mediaPrimary!.url,
                url_t: _product!.mediaPrimary!.url_t,
                type: _product!.mediaPrimary!.type,
              ));
        }
      }
    }

    return Container(
      height: SizeConfig.screenHeight * .35,
      child: PhotoViewGallery.builder(
        itemCount: _product!.media!.length,
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final img = _product!.media![index];

          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(img.url != null &&
                    img.url!.isNotEmpty
                ? img.url!
                : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg'),
            initialScale: PhotoViewComputedScale.contained * 0.8,
            heroAttributes: PhotoViewHeroAttributes(
                tag: _product!.productid! +
                    index.toString() +
                    DateTime.now().toIso8601String()),
          );
        },
        onPageChanged: (index) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded /
                      num.parse(event.expectedTotalBytes.toString()),
            ),
          ),
        ),
        backgroundDecoration: BoxDecoration(
          color: Colors.grey.shade900,
        ),
      ),
    );
  }

  _onDeleteTapped() {
    DialogMessage.show(
      context,
      title: 'Delete Product',
      message: 'Are you sure you want to delete this product?',
      buttonText: 'Yes',
      firstButtonClicked: () =>
          _productBloc.add(DeleteProduct(_product!.productid!)),
      secondButtonText: 'No',
      hideClose: true,
    );
  }

  _onEditTapped() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditScreen(product: _product!),
      ),
    );
    _productBloc.add(GetProductDetails(widget.productId));
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<dynamic> _onMarkerTapped(ProductModel product) async {
    print(product.address!.toJson());
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Color(0x79FFFFFF),
      barrierColor: Color(0x99000000),
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: SizeConfig.screenWidth * .2,
                    height: SizeConfig.screenWidth * .2,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: product.mediaPrimary != null
                            ? NetworkImage(product.mediaPrimary!.url!)
                            : AssetImage('assets/images/image_placeholder.jpg')
                                as ImageProvider<Object>,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productname ?? '',
                          style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          product.price == null
                              ? ''
                              : '\$ ${product.price!.toStringAsFixed(2)}',
                          style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(
                              Icons.location_pin,
                              size: 20.0,
                              color: Colors.red,
                            ),
                            Text(
                              product.address!.address!.isNotEmpty
                                  ? product.address!.address!
                                  : 'No address',
                              style: Style.subtitle2
                                  .copyWith(color: kBackgroundColor),
                            )
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Padding(
                                padding:
                                    EdgeInsets.only(right: i != 5 ? 5.0 : 0.0),
                                child: Icon(
                                  i <
                                          (product.rating != null
                                              ? product.rating!.round()
                                              : 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Color(0xFFFFC107),
                                  size: 20.0,
                                ),
                              );
                            }),
                            Text(
                              product.rating != null
                                  ? product.rating!.toStringAsFixed(1)
                                  : '0',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
