import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/reviews/user_review_list_screen.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';

import '../../backend.dart';

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

  Stream<QuerySnapshot<Map<String, dynamic>>>? _storeLikeStream;

  bool _isFollowing = false;

  @override
  void initState() {
    _storeBloc.add(InitializeStoreScreen(widget.userId));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      backgroundColor: Colors.white,
      indicatorColor: kBackgroundColor,
      child: Scaffold(
        body: Container(
          child: Column(
            children: [
              CustomAppBar(
                label: '$storeOwnerName\'s Store',
              ),
              _storeOwner != null
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 10.0,
                      ),
                      child: Row(
                        children: [
                          _buildPhoto(),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildInfoItem(
                                    label: 'Store Owner',
                                    controller: TextEditingController(
                                        text: storeOwnerName),
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
                                  SizedBox(height: 12.0),
                                  StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>>(
                                    stream: _storeLikeStream,
                                    builder: (context, snapshot) {
                                      bool liked = false;

                                      print(snapshot.data);

                                      if (snapshot.data != null) {
                                        if (snapshot.data!.docs.isNotEmpty)
                                          liked = true;
                                      }
                                      return InkWell(
                                        onTap: () => _storeBloc.add(
                                          EditUserLike(
                                            user: _storeOwner!,
                                            likeCount: liked ? -1 : 1,
                                          ),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: kBackgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.library_add_check,
                                                size:
                                                    SizeConfig.textScaleFactor *
                                                        13,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 5.0),
                                              Text(
                                                liked ? 'Following' : 'Follow',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: SizeConfig
                                                          .textScaleFactor *
                                                      15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  UserReviewListScreen(userId: widget.userId))),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 10.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'User Reviews',
                              style: Style.subtitle2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              FontAwesomeIcons.chevronRight,
                              color: Colors.white,
                              size: 14.0,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(1, 1),
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            child: Icon(
                              _selectedView != 'map'
                                  ? FontAwesomeIcons.mapMarkedAlt
                                  : FontAwesomeIcons.thLarge,
                              size: 16.0,
                              color: kBackgroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: MultiBlocListener(
                  listeners: [
                    BlocListener(
                      bloc: _productBloc,
                      listener: (context, state) {
                        if (state is ProductLoading) {
                          ProgressHUD.of(context)!.show();
                        } else {
                          ProgressHUD.of(context)!.dismiss();
                        }

                        if (state is GetFirstProductsSuccess) {
                          _refreshController.refreshCompleted();
                          _pagingController.refresh();
                          if (state.list.isNotEmpty) {
                            _list.addAll(state.list);
                            lastProduct = state.list.last;
                            if (state.list.length == productCount) {
                              _pagingController.appendPage(
                                  state.list, currentPage + 1);
                            } else {
                              _pagingController.appendLastPage(state.list);
                            }

                            _pagingController.addPageRequestListener((pageKey) {
                              if (lastProduct != null) {
                                _productBloc.add(
                                  GetNextProducts(
                                    listType: 'user',
                                    lastProductId: lastProduct!.productid!,
                                    startAfterVal:
                                        lastProduct!.price.toString(),
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
                              _pagingController.appendPage(
                                  state.list, currentPage + 1);
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
                        if (state is LoadingStore) {
                          ProgressHUD.of(context)!.show();
                        } else {
                          setState(() {
                            ProgressHUD.of(context)!.dismiss();
                          });
                        }

                        if (state is InitializedStoreScreen) {
                          print(state.user.toJson());
                          setState(() {
                            _storeOwner = state.user;
                            storeOwnerName = _storeOwner!.display_name!;
                            _storeLikeStream = state.storeLikeStream;
                          });

                          _storeLikeStream!.listen((snapshot) {
                            setState(() {
                              if (snapshot.docs.isNotEmpty)
                                _isFollowing = true;
                              else
                                _isFollowing = false;
                            });
                          });
                          _productBloc.add(
                              GetFirstProducts('user', userId: widget.userId));
                        }

                        if (state is EditUserLikeSuccess) {
                          DialogMessage.show(
                            context,
                            message:
                                'You ${_isFollowing ? 'followed' : 'unfollowed'} this store!',
                          );
                        }
                      },
                    ),
                  ],
                  child: Container(
                      child: _selectedView == 'grid'
                          ? _buildGridView()
                          : _buildMapView()),
                ),
              ),
            ],
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
      child: TapkatGoogleMap(
        onCameraIdle: (latLng) => googleMapsCenter = latLng,
        initialLocation: googleMapsCenter ?? LatLng(1.3631246, 103.8325137),
        onMapCreated: (controller) {
          googleMapsController = controller;
        },
        markers: _list
            .map(
              (product) => TapkatMarker(
                  product.productid!,
                  LatLng(
                    product.address != null && product.address!.location != null
                        ? product.address!.location!.latitude!.toDouble()
                        : 0.00,
                    product.address != null && product.address!.location != null
                        ? product.address!.location!.longitude!.toDouble()
                        : 0.00,
                  ),
                  () => _onMarkerTapped(product),
                  product),
            )
            .toList(),
      ),
    );
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
                  SizedBox(width: 10.0),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(
                          productId: product.productid ?? '',
                        ),
                      ),
                    ),
                    child: Container(
                      child: Icon(
                        Icons.chevron_right,
                        color: kBackgroundColor,
                        size: 30.0,
                      ),
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

  Widget _buildGridView() {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () => _storeBloc.add(InitializeStoreScreen(widget.userId)),
      child: PagedGridView<int, ProductModel>(
        pagingController: _pagingController,
        showNewPageProgressIndicatorAsGridChild: false,
        showNewPageErrorIndicatorAsGridChild: false,
        showNoMoreItemsIndicatorAsGridChild: false,
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 16,
          crossAxisCount: 2,
        ),
        builderDelegate: PagedChildBuilderDelegate<ProductModel>(
          itemBuilder: (context, product, index) {
            return Center(
              child: StreamBuilder<List<UserLikesRecord?>>(
                  stream: queryUserLikesRecord(
                    queryBuilder: (userLikesRecord) => userLikesRecord
                        .where('userid', isEqualTo: widget.userId)
                        .where('productid', isEqualTo: product.productid),
                    singleRecord: true,
                  ),
                  builder: (context, snapshot) {
                    bool liked = false;
                    UserLikesRecord? record;
                    if (snapshot.hasData) {
                      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                        record = snapshot.data!.first;
                        if (record != null) {
                          liked = record.liked ?? false;
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

                    if (product.mediaPrimary != null &&
                        product.mediaPrimary!.url!.isEmpty &&
                        product.mediaPrimary!.url_t!.isEmpty &&
                        product.media != null &&
                        product.media!.isNotEmpty)
                      thumbnail = product.media!.first.url_t != null
                          ? product.media!.first.url_t!
                          : product.media!.first.url!;

                    return BarterListItem(
                      product: product,
                      height: SizeConfig.screenHeight * 0.21,
                      width: SizeConfig.screenWidth * 0.40,
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
                    );
                  }),
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
      margin: EdgeInsets.only(bottom: 3.0),
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Text(
            label,
            style: Style.fieldTitle.copyWith(
                color: kBackgroundColor,
                fontSize: SizeConfig.textScaleFactor * 11),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                controller.text,
                textAlign: TextAlign.right,
                style: Style.fieldText
                    .copyWith(fontSize: SizeConfig.textScaleFactor * 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stack _buildPhoto() {
    return Stack(
      children: [
        Container(
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
          height: SizeConfig.screenWidth * .24,
          width: SizeConfig.screenWidth * .24,
        ),
      ],
    );
  }
}
