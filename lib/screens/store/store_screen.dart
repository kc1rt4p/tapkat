import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/store_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/reviews/user_review_list_screen.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/helper.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:label_marker/label_marker.dart';
import 'package:tapkat/utilities/application.dart' as application;

class StoreScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const StoreScreen({Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _productBloc = ProductBloc();
  final _storeBloc = StoreBloc();
  List<ProductModel> _list = [];

  final _storeRepo = StoreRepository();

  int currentPage = 0;

  List<ProductModel> indicators = [];
  List<ProductMarkersRecord?> productMarkers = [];

  String storeOwnerName = '';
  UserModel? _storeOwner;

  ProductModel? lastProduct;

  final _refreshController = RefreshController();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;

  String _selectedView = 'grid';

  bool _isFollowing = false;

  bool _isLoading = true;

  Set<Marker> _markers = {};

  final _userRepo = UserRepository();

  @override
  void initState() {
    application.currentScreen = 'Store Screen';
    _storeBloc.add(InitializeStoreScreen(widget.userId));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      backgroundColor: Colors.white,
      indicatorColor: kBackgroundColor,
      child: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _productBloc,
            listener: (context, state) {
              print('0-----> current state: $state');
              if (state is ProductLoading) {
                ProgressHUD.of(context)!.show();
              } else {
                ProgressHUD.of(context)!.dismiss();
              }

              if (state is GetFirstProductsSuccess) {
                if (state.list.isNotEmpty) {
                  _list.addAll(state.list);
                  lastProduct = state.list.last;
                  if (state.list.length == productCount) {
                    _pagingController.appendPage(state.list, currentPage + 1);
                  } else {
                    _pagingController.appendLastPage(state.list);
                  }

                  _pagingController.addPageRequestListener((pageKey) {
                    if (lastProduct != null) {
                      _productBloc.add(
                        GetNextProducts(
                          listType: 'user',
                          lastProductId: lastProduct!.productid!,
                          sortBy: 'distance',
                          distance: 50000,
                          startAfterVal: lastProduct!.price.toString(),
                          userId: widget.userId,
                        ),
                      );
                    }
                  });
                }
              }

              if (state is GetProductsSuccess) {
                if (state.list.isNotEmpty) {
                  _list.addAll(state.list);
                  lastProduct = state.list.last;
                  if (state.list.length == productCount) {
                    _pagingController.appendPage(state.list, currentPage + 1);
                  } else {
                    _pagingController.appendLastPage(state.list);
                  }
                } else {
                  _pagingController.appendLastPage([]);
                }
              }
            },
          ),
          BlocListener(
            bloc: _storeBloc,
            listener: (context, state) {
              print('0-----> CURRENT STATE: $state');
              if (state is LoadingStore) {
                ProgressHUD.of(context)!.show();
                setState(() {
                  _isLoading = true;
                });
              } else {
                setState(() {
                  _isLoading = false;
                });
                ProgressHUD.of(context)!.dismiss();
              }

              if (state is StateError) {
                DialogMessage.show(context, message: state.message);
              }

              if (state is InitializedStoreScreen) {
                _refreshController.refreshCompleted();
                _pagingController.refresh();
                _list.clear();
                setState(() {
                  _storeOwner = state.user;
                  storeOwnerName = _storeOwner!.display_name!;
                });
                _productBloc.add(GetFirstProducts(
                  listType: 'user',
                  userid: widget.userId,
                  sortBy: 'distance',
                  distance: 50000,
                ));
              }

              if (state is EditUserLikeSuccess) {
                _storeBloc.add(InitializeStoreScreen(widget.userId));
                DialogMessage.show(
                  context,
                  message:
                      'You ${_isFollowing ? 'unfollowed' : 'followed'} this store!',
                );
              }
            },
          ),
        ],
        child: Scaffold(
          body: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: '$storeOwnerName\'s Store',
                ),
                _storeOwner != null && !_isLoading
                    ? Container(
                        constraints: BoxConstraints(maxWidth: 500.0),
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 20.0,
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                _buildPhoto(),
                                SizedBox(height: 5.0),
                                _storeOwner != null &&
                                        _storeOwner!.userid !=
                                            application.currentUser!.uid
                                    ? StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>>(
                                        stream: _storeRepo.streamStoreLike(
                                            _storeOwner!.userid!,
                                            application.currentUser!.uid),
                                        builder: (context, snapshot) {
                                          bool liked = false;

                                          if (snapshot.data != null) {
                                            if (snapshot
                                                .data!.docs.isNotEmpty) {
                                              liked = true;

                                              _isFollowing = true;
                                            } else {
                                              liked = false;

                                              _isFollowing = false;
                                            }
                                          } else {
                                            _isFollowing = false;
                                          }

                                          return InkWell(
                                            onTap: () => _storeBloc.add(
                                              EditUserLike(
                                                user: _storeOwner!,
                                                likeCount: liked ? -1 : 1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: kBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.0),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 3.0,
                                                  horizontal: 16.0,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      liked
                                                          ? Icons.remove_circle
                                                          : Icons.library_add,
                                                      size: SizeConfig
                                                              .textScaleFactor *
                                                          11.5,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 5.0),
                                                    Text(
                                                      liked
                                                          ? 'Unfollow'
                                                          : 'Follow',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: SizeConfig
                                                                .textScaleFactor *
                                                            11.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(),
                              ],
                            ),
                            SizedBox(width: 20.0),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      SizeConfig.screenWidth > 500
                                          ? CrossAxisAlignment.start
                                          : CrossAxisAlignment.center,
                                  children: [
                                    _buildInfoItem(
                                      label: 'Store Owner',
                                      controller: TextEditingController(
                                          text: storeOwnerName),
                                    ),
                                    _buildInfoItem(
                                      label: 'Followers',
                                      controller: TextEditingController(
                                          text: _storeOwner!.likes != null
                                              ? _storeOwner!.likes.toString()
                                              : '0'),
                                    ),
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 300.0,
                                      ),
                                      margin: EdgeInsets.only(bottom: 3.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Rating',
                                            style: Style.fieldTitle.copyWith(
                                                color: kBackgroundColor,
                                                fontSize:
                                                    SizeConfig.textScaleFactor *
                                                        11),
                                          ),
                                          Spacer(),
                                          InkWell(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserReviewListScreen(
                                                  userId: widget.userId,
                                                ),
                                              ),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                      color: kBackgroundColor),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  RatingBar.builder(
                                                    ignoreGestures: true,
                                                    initialRating: _storeOwner!
                                                                .rating !=
                                                            null
                                                        ? _storeOwner!.rating!
                                                            .roundToDouble()
                                                        : 0,
                                                    minRating: 0,
                                                    direction: Axis.horizontal,
                                                    allowHalfRating: true,
                                                    itemCount: 5,
                                                    itemSize: SizeConfig
                                                            .textScaleFactor *
                                                        13,
                                                    tapOnlyMode: true,

                                                    itemBuilder: (context, _) =>
                                                        Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    ),
                                                    onRatingUpdate: (rating) {},
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
                                                    _storeOwner != null &&
                                                            _storeOwner!
                                                                    .rating !=
                                                                null
                                                        ? _storeOwner!.rating!
                                                            .toStringAsFixed(1)
                                                        : '0',
                                                    style: TextStyle(
                                                        fontSize: SizeConfig
                                                                .textScaleFactor *
                                                            13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildInfoItem(
                                      label: 'Location',
                                      controller: TextEditingController(
                                          text: (_storeOwner!.address != null &&
                                                  _storeOwner!.city != null &&
                                                  _storeOwner!.country != null)
                                              ? (_storeOwner!.address ?? '') +
                                                  ', ' +
                                                  (_storeOwner!.city ?? '') +
                                                  ', ' +
                                                  (_storeOwner!.country ?? '')
                                              : ''),
                                      suffix: Icon(
                                        FontAwesomeIcons.mapMarked,
                                        color: kBackgroundColor,
                                        size: 12.0,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    _buildSocialMediaBtns(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Shimmer.fromColors(
                                  child: Container(
                                    height: SizeConfig.screenWidth * .26,
                                    width: SizeConfig.screenWidth * .26,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  baseColor: kBackgroundColor.withOpacity(0.8),
                                  highlightColor: kBackgroundColor,
                                ),
                                SizedBox(height: 5.0),
                                Shimmer.fromColors(
                                  child: Container(
                                    width: 30.0,
                                    height: 14.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.grey,
                                    ),
                                  ),
                                  baseColor: kBackgroundColor.withOpacity(0.8),
                                  highlightColor: kBackgroundColor,
                                ),
                              ],
                            ),
                            SizedBox(width: 20.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Shimmer.fromColors(
                                          child: Container(
                                            width: double.infinity,
                                            height: 14.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          baseColor:
                                              kBackgroundColor.withOpacity(0.8),
                                          highlightColor: kBackgroundColor,
                                        ),
                                      ),
                                      SizedBox(width: 10.0),
                                      Expanded(
                                        flex: 3,
                                        child: Shimmer.fromColors(
                                          child: Container(
                                            width: double.infinity,
                                            height: 14.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          baseColor:
                                              kBackgroundColor.withOpacity(0.8),
                                          highlightColor: kBackgroundColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Shimmer.fromColors(
                                          child: Container(
                                            width: double.infinity,
                                            height: 14.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          baseColor:
                                              kBackgroundColor.withOpacity(0.8),
                                          highlightColor: kBackgroundColor,
                                        ),
                                      ),
                                      SizedBox(width: 10.0),
                                      Expanded(
                                        flex: 3,
                                        child: Shimmer.fromColors(
                                          child: Container(
                                            width: double.infinity,
                                            height: 14.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          baseColor:
                                              kBackgroundColor.withOpacity(0.8),
                                          highlightColor: kBackgroundColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Shimmer.fromColors(
                                          child: Container(
                                            width: double.infinity,
                                            height: 14.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          baseColor:
                                              kBackgroundColor.withOpacity(0.8),
                                          highlightColor: kBackgroundColor,
                                        ),
                                      ),
                                      SizedBox(width: 10.0),
                                      Expanded(
                                        flex: 3,
                                        child: Shimmer.fromColors(
                                          child: Container(
                                            width: double.infinity,
                                            height: 14.0,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          baseColor:
                                              kBackgroundColor.withOpacity(0.8),
                                          highlightColor: kBackgroundColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.0),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Shimmer.fromColors(
                                      child: Container(
                                        width: double.infinity,
                                        height: 20.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          color: Colors.grey,
                                        ),
                                      ),
                                      baseColor:
                                          kBackgroundColor.withOpacity(0.8),
                                      highlightColor: kBackgroundColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              margin: EdgeInsets.zero,
                              controller: TextEditingController(),
                              backgroundColor: kBackgroundColor,
                              textColor: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10.0),
                          InkWell(
                            onTap: _onSelectView,
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    offset: Offset(1, 1),
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedView != 'map'
                                        ? FontAwesomeIcons.mapMarkedAlt
                                        : FontAwesomeIcons.thLarge,
                                    size: 16.0,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text(_selectedView != 'map' ? 'Map' : 'Grid',
                                      style: TextStyle(
                                        color: Colors.white,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                      child: _selectedView == 'grid'
                          ? _buildGridView()
                          : _buildMapView()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onSelectView() {
    setState(() {
      _selectedView = _selectedView == 'grid' ? 'map' : 'grid';
    });
  }

  _buildMapView() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
      child: TapkatGoogleMap(
        onCameraIdle: (latLng) => googleMapsCenter = latLng,
        initialLocation: LatLng(
            application.currentUserLocation!.latitude!.toDouble(),
            application.currentUserLocation!.longitude!.toDouble()),
        onMapCreated: (controller) {
          googleMapsController = controller;
          _buildMarkers();
        },
        markers: _markers.toSet(),
      ),
    );
  }

  _buildMarkers() async {
    await Future.forEach<ProductModel>(_list, (product) async {});

    _list.forEach((product) {
      _markers
          .addLabelMarker(
            LabelMarker(
              onTap: () => onMarkerTapped(context, product),
              label: product.productname ?? '',
              markerId: MarkerId(product.productid!),
              position: LatLng(
                product.address != null && product.address!.location != null
                    ? product.address!.location!.latitude!.toDouble()
                    : 0.00,
                product.address != null && product.address!.location != null
                    ? product.address!.location!.longitude!.toDouble()
                    : 0.00,
              ),
              backgroundColor: kBackgroundColor,
            ),
          )
          .then((value) => setState(() {}));
    });

    // if (markers.isNotEmpty) {
    //   setState(() {
    //     _markers = markers;
    //   });
    // }
  }

  Widget _buildGridView() {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () => _storeBloc.add(InitializeStoreScreen(widget.userId)),
      child: PagedGridView<int, ProductModel>(
        pagingController: _pagingController,
        showNewPageProgressIndicatorAsGridChild: false,
        showNewPageErrorIndicatorAsGridChild: false,
        showNoMoreItemsIndicatorAsGridChild: false,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SizeConfig.screenWidth > 500 ? 3 : 2,
        ),
        builderDelegate: PagedChildBuilderDelegate<ProductModel>(
          itemBuilder: (context, product, index) {
            return FittedBox(
              child: BarterListItem(
                product: product,
                onTapped: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      productId: product.productid ?? '',
                    ),
                  ),
                ),
                onLikeTapped: (val) {
                  if (val.isNegative) {
                    _productBloc.add(AddLike(product));
                  } else {
                    _productBloc.add(Unlike(product));
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Container _buildInfoItem({
    required String label,
    required TextEditingController controller,
    Widget? suffix,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 300.0,
      ),
      margin: EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Text(
            label,
            style: Style.fieldTitle.copyWith(
                color: kBackgroundColor,
                fontSize: SizeConfig.textScaleFactor * 10),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                controller.text,
                textAlign: TextAlign.right,
                style: Style.fieldText.copyWith(
                    fontSize: SizeConfig.textScaleFactor * 11,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaBtns() {
    if (_storeOwner == null) {
      return Container(
        constraints: BoxConstraints(maxWidth: 500.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Shimmer.fromColors(
              child: Container(
                height: SizeConfig.screenWidth * .06,
                width: SizeConfig.screenWidth * .06,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              baseColor: kBackgroundColor.withOpacity(0.8),
              highlightColor: kBackgroundColor,
            ),
            SizedBox(width: 10.0),
            Shimmer.fromColors(
              child: Container(
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              baseColor: kBackgroundColor.withOpacity(0.8),
              highlightColor: kBackgroundColor,
            ),
            SizedBox(width: 10.0),
            Shimmer.fromColors(
              child: Container(
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              baseColor: kBackgroundColor.withOpacity(0.8),
              highlightColor: kBackgroundColor,
            ),
            SizedBox(width: 10.0),
            Shimmer.fromColors(
              child: Container(
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              baseColor: kBackgroundColor.withOpacity(0.8),
              highlightColor: kBackgroundColor,
            ),
            SizedBox(width: 10.0),
            Shimmer.fromColors(
              child: Container(
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              baseColor: kBackgroundColor.withOpacity(0.8),
              highlightColor: kBackgroundColor,
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: 500.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: _storeOwner!.fb_profile != null &&
                _storeOwner!.fb_profile!.isNotEmpty,
            child: InkWell(
              onTap: () => _launchURL(_storeOwner!.fb_profile!),
              child: Container(
                constraints: BoxConstraints(maxWidth: 30.0),
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                margin: EdgeInsets.only(right: 10.0),
                child: Icon(
                  FontAwesomeIcons.facebookF,
                  color: Colors.white,
                  size: SizeConfig.textScaleFactor * 14,
                ),
              ),
            ),
          ),
          Visibility(
            visible: _storeOwner!.ig_profile != null &&
                _storeOwner!.ig_profile!.isNotEmpty,
            child: InkWell(
              onTap: () => _launchURL(_storeOwner!.ig_profile!),
              child: Container(
                constraints: BoxConstraints(maxWidth: 30.0),
                margin: EdgeInsets.only(right: 10.0),
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.instagram,
                  color: Colors.white,
                  size: SizeConfig.textScaleFactor * 14,
                ),
              ),
            ),
          ),
          Visibility(
            visible: _storeOwner!.yt_profile != null &&
                _storeOwner!.yt_profile!.isNotEmpty,
            child: InkWell(
              onTap: () => _launchURL(_storeOwner!.yt_profile!),
              child: Container(
                constraints: BoxConstraints(maxWidth: 30.0),
                margin: EdgeInsets.only(right: 10.0),
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.youtube,
                  color: Colors.white,
                  size: SizeConfig.textScaleFactor * 14,
                ),
              ),
            ),
          ),
          Visibility(
            visible: _storeOwner!.tt_profile != null &&
                _storeOwner!.tt_profile!.isNotEmpty,
            child: InkWell(
              onTap: () => _launchURL(_storeOwner!.tt_profile!),
              child: Container(
                constraints: BoxConstraints(maxWidth: 30.0),
                margin: EdgeInsets.only(right: 10.0),
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.tiktok,
                  color: Colors.white,
                  size: SizeConfig.textScaleFactor * 14,
                ),
              ),
            ),
          ),
          Visibility(
            visible: _storeOwner!.tw_profile != null &&
                _storeOwner!.tw_profile!.isNotEmpty,
            child: InkWell(
              onTap: () => _launchURL(_storeOwner!.tw_profile!),
              child: Container(
                constraints: BoxConstraints(maxWidth: 30.0),
                height: SizeConfig.screenWidth * .07,
                width: SizeConfig.screenWidth * .07,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.twitter,
                  color: Colors.white,
                  size: SizeConfig.textScaleFactor * 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String website) async {
    String pattern =
        r'^((?:.|\n)*?)((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?)';
    RegExp regExp = RegExp(pattern);
    if (!(regExp.hasMatch(website))) {
      DialogMessage.show(context, message: 'Invalid URL');
      return;
    }
    if (!await launchURL(website)) throw 'Could not launch $website';
  }

  Widget _buildPhoto() {
    return StreamBuilder<bool>(
      stream: _userRepo.streamUserOnlineStatus(_storeOwner!.userid!),
      builder: (context, snapshot) {
        bool online = false;
        if (snapshot.hasData) {
          online = snapshot.data ?? false;
        }
        return Stack(
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: 150.0,
                maxWidth: 150.0,
              ),
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100.0),
                image: DecorationImage(
                  image: _storeOwner != null &&
                          (_storeOwner!.photo_url != null &&
                              _storeOwner!.photo_url != '')
                      ? CachedNetworkImageProvider(_storeOwner!.photo_url!)
                      : AssetImage('assets/images/profile_placeholder.png')
                          as ImageProvider<Object>,
                  scale: 1.0,
                  fit: BoxFit.cover,
                ),
              ),
              height: SizeConfig.screenWidth * .26,
              width: SizeConfig.screenWidth * .26,
            ),
            Positioned(
              top: 20,
              right: 15,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 12.0,
                    width: 12.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    height: 10.0,
                    width: 10.0,
                    decoration: BoxDecoration(
                      color: online ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
