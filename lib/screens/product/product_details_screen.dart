import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_edit_screen.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
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
  late AuthBloc _authBloc;
  final _carouselController = CarouselController();
  int _currentCarouselIndex = 0;
  Map<String, dynamic>? mappedProductDetails;
  ProductModel? _product;
  User? _user;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
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
                  if (state is ProductLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is DeleteProductSuccess) {
                    await DialogMessage.show(context,
                        message: 'The product has been deleted.');

                    Navigator.pop(context);
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

                  if (state is AddLikeSuccess ||
                      state is AddRatingSuccess ||
                      state is UnlikeSuccess) {
                    _productBloc.add(GetProductDetails(widget.productId));
                  }
                },
              ),
              BlocListener(
                bloc: _authBloc,
                listener: (context, state) {
                  if (state is GetCurrentUsersuccess) {
                    setState(() {
                      _user = state.user;
                    });
                    _productBloc.add(GetProductDetails(widget.productId));
                  }
                },
              ),
            ],
            child: Container(
              child: Column(
                children: [
                  CustomAppBar(
                    label: 'Product Details',
                  ),
                  Expanded(
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
                                              '(${_product != null && _product!.status != null && _product!.status!.toLowerCase() == 'available' ? _product!.status!.toUpperCase() : 'AVAILABLE'})',
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
                                          // Column(
                                          //   crossAxisAlignment:
                                          //       CrossAxisAlignment.end,
                                          //   children: [
                                          //     Text(
                                          //       'Listed by:',
                                          //       style: TextStyle(
                                          //         fontSize: 13.0,
                                          //         color: Color(0xFF414141),
                                          //       ),
                                          //     ),
                                          //     Text(
                                          //       _product != null &&
                                          //               _product!
                                          //                   .userid!.isNotEmpty
                                          //           ? _product!.userid!.length >
                                          //                   8
                                          //               ? '${_product!.userid!.substring(0, 8)}...'
                                          //               : _product!.userid!
                                          //           : '',
                                          //       overflow: TextOverflow.ellipsis,
                                          //       style: TextStyle(
                                          //         fontSize: 15.0,
                                          //         fontWeight: FontWeight.w600,
                                          //       ),
                                          //     ),
                                          //   ],
                                          // ),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _productBloc.add(
                                                            AddRating(_product!,
                                                                i + 1));
                                                      },
                                                      child: Icon(
                                                        i <
                                                                (_product !=
                                                                            null &&
                                                                        _product!.rating !=
                                                                            null
                                                                    ? _product!
                                                                        .rating!
                                                                        .round()
                                                                    : 0)
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color:
                                                            Color(0xFFFFC107),
                                                        size: 20.0,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _product != null &&
                                                    _product!.rating != null
                                                ? _product!.rating!
                                                    .toStringAsFixed(1)
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
                                                    _user != null &&
                                                            _product != null
                                                        ? Visibility(
                                                            visible:
                                                                !widget.ownItem,
                                                            child: StreamBuilder<
                                                                    List<
                                                                        UserLikesRecord?>>(
                                                                stream:
                                                                    queryUserLikesRecord(
                                                                  queryBuilder: (userLikesRecord) => userLikesRecord
                                                                      .where(
                                                                          'userid',
                                                                          isEqualTo: _user!
                                                                              .uid)
                                                                      .where(
                                                                          'productid',
                                                                          isEqualTo:
                                                                              _product!.productid),
                                                                  singleRecord:
                                                                      true,
                                                                ),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  print(
                                                                      '=== snapshot= ${snapshot.data}');
                                                                  bool liked =
                                                                      false;
                                                                  UserLikesRecord?
                                                                      record;
                                                                  if (snapshot
                                                                      .hasData) {
                                                                    if (snapshot.data !=
                                                                            null &&
                                                                        snapshot
                                                                            .data!
                                                                            .isNotEmpty) {
                                                                      record = snapshot
                                                                          .data!
                                                                          .first;
                                                                      if (record !=
                                                                          null) {
                                                                        liked = record.liked ??
                                                                            false;
                                                                        print(
                                                                            '==== $record');
                                                                      }
                                                                    }
                                                                  }

                                                                  return GestureDetector(
                                                                    onTap: () {
                                                                      if (record !=
                                                                          null) {
                                                                        final newData =
                                                                            createUserLikesRecordData(
                                                                          liked:
                                                                              !record.liked!,
                                                                        );

                                                                        record
                                                                            .reference!
                                                                            .update(newData);
                                                                        if (liked) {
                                                                          _productBloc
                                                                              .add(
                                                                            Unlike(_product!),
                                                                          );
                                                                        } else {
                                                                          _productBloc
                                                                              .add(AddLike(_product!));
                                                                        }
                                                                      } else {
                                                                        _productBloc
                                                                            .add(AddLike(_product!));
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
                                                                }),
                                                          )
                                                        : Container(),
                                                    SizedBox(width: 5.0),
                                                    Visibility(
                                                      visible: !widget.ownItem,
                                                      child: Text(_product !=
                                                                  null &&
                                                              _product!.likes !=
                                                                  null
                                                          ? _product!.likes!
                                                              .toString()
                                                          : '0'),
                                                    ),
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !widget.ownItem &&
                                _product != null &&
                                _product!.userid != _user!.uid,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
                              child: CustomButton(
                                label: 'BARTER',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BarterScreen(product: _product!),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: widget.ownItem,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildPhotos() {
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
                tag: _product!.productid! + index.toString()),
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
}
