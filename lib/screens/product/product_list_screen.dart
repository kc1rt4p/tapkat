import 'dart:typed_data';
import 'dart:ui';

import 'package:clippy_flutter/clippy_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:toggle_switch/toggle_switch.dart';

class ProductListScreen extends StatefulWidget {
  final bool showAdd;

  final String listType;
  final String? userId;
  final bool ownListing;
  final String initialView;

  const ProductListScreen({
    Key? key,
    required this.listType,
    this.userId,
    this.showAdd = false,
    this.ownListing = false,
    this.initialView = 'grid',
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productBloc = ProductBloc();
  late String _title;
  List<ProductModel> _list = [];

  String _selectedView = 'grid'; //grid or map

  int currentPage = 0;

  List<ProductModel> indicators = [];

  final _keywordTextController = TextEditingController();

  final _refreshController = RefreshController();

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  ProductModel? lastProduct;

  bool _loading = false;
  List<Marker> _markers = [];

  String _selectedSortBy = 'distance';
  List<String> sortByOptions = [
    'Distance',
    'Name',
    'Price',
    'Rating',
  ];
  int _selectedRadius = 5000;
  List<int> radiusOptions = [1000, 5000, 10000, 20000, 50000];
  ProductCategoryModel? _selectedCategory;

  List<ProductCategoryModel> _categoryList = [];

  @override
  void initState() {
    _setTitle();

    _productBloc.add(InitializeAddUpdateProduct());

    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void _setTitle() {
    switch (widget.listType) {
      case 'reco':
        _title = 'Recommended For You';
        break;
      case 'demand':
        _title = 'What\'s Hot?';
        break;
      case 'free':
        _title = 'Free Items';
        break;
      default:
        _title = 'Your items';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xFFEBFBFF),
      body: ProgressHUD(
        barrierEnabled: false,
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: BlocListener(
          bloc: _productBloc,
          listener: (context, state) {
            if (state is ProductLoading) {
              setState(() {
                _loading = true;
              });
            } else {
              setState(() {
                _loading = false;
              });
            }

            if (state is InitializeAddUpdateProductSuccess) {
              _categoryList = state.categories;

              // if (widget.listType == 'reco' &&
              //     application.currentUserModel!.interests != null &&
              //     application.currentUserModel!.interests!.isNotEmpty) {
              //   setState(() {
              //     _selectedCategory = _categoryList.firstWhere((cat) =>
              //         cat.code == application.currentUserModel!.interests![0]);
              //   });
              // }

              _productBloc.add(GetFirstProducts(
                userid: application.currentUser!.uid,
                listType: widget.listType,
                sortBy: _selectedSortBy,
                distance: _selectedRadius,
                category: _selectedCategory != null
                    ? [_selectedCategory!.code!]
                    : null,
              ));
            }

            if (state is GetFirstProductsSuccess) {
              _refreshController.refreshCompleted();
              _pagingController.refresh();
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

              if (widget.initialView != 'grid') {
                _onSelectView();
              }

              _pagingController.addPageRequestListener((pageKey) {
                if (lastProduct != null) {
                  var startAfterVal;
                  switch (_selectedSortBy.toLowerCase()) {
                    case 'rating':
                      startAfterVal = lastProduct!.rating;
                      break;
                    case 'name':
                      startAfterVal = lastProduct!.productname;
                      break;
                    case 'distance':
                      startAfterVal = lastProduct!.distance;
                      break;

                    default:
                      startAfterVal = lastProduct!.price;
                  }
                  _productBloc.add(
                    GetNextProducts(
                      listType: widget.listType,
                      lastProductId: lastProduct!.productid!,
                      startAfterVal: widget.listType != 'demand'
                          ? startAfterVal
                          : lastProduct!.likes.toString(),
                      userId: widget.listType == 'user' ? widget.userId : '',
                      sortBy: _selectedSortBy,
                      distance: _selectedRadius,
                      category: _selectedCategory != null
                          ? [_selectedCategory!.code!]
                          : null,
                    ),
                  );
                } else {
                  _pagingController.refresh();
                }
              });
            }

            if (state is GetProductsSuccess) {
              // setState(() {
              //   _list = state.list;

              //   indicators.add(_list.last);
              // });
              // print('==== CURRENT PAGE: $currentPage');

              // indicators.asMap().forEach(
              //     (key, value) => print('==== page $key: ${value.productid}'));
              print('HEYYYY');
              if (state.list.isNotEmpty) {
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
          child: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: _title,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              margin: EdgeInsets.symmetric(horizontal: 20.0),
                              controller: _keywordTextController,
                              backgroundColor:
                                  Color(0xFF005F73).withOpacity(0.3),
                              onSubmitted: (val) => _onSearchSubmitted(val),
                            ),
                          ),
                          // Visibility(
                          //   visible: !widget.ownListing,
                          //   child: Row(
                          //     children: [
                          //       SizedBox(width: 10.0),
                          //       InkWell(
                          //         onTap: _onSelectView,
                          //         child: Container(
                          //           padding: EdgeInsets.all(8.0),
                          //           decoration: BoxDecoration(
                          //             color: Color(0xFF005F73).withOpacity(0.3),
                          //             borderRadius: BorderRadius.circular(10.0),
                          //           ),
                          //           child: Icon(
                          //             _selectedView != 'map'
                          //                 ? FontAwesomeIcons.mapMarkedAlt
                          //                 : FontAwesomeIcons.thLarge,
                          //             size: 16.0,
                          //             color: kBackgroundColor,
                          //           ),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category',
                                    style: TextStyle(
                                      fontSize: SizeConfig.textScaleFactor * 12,
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  InkWell(
                                    onTap: _onFilterByCategory,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: kBackgroundColor,
                                            width: 0.6,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _selectedCategory != null
                                                ? _selectedCategory!.name!
                                                : 'All',
                                            style: Style.subtitle2.copyWith(
                                              color: kBackgroundColor,
                                              fontSize:
                                                  SizeConfig.textScaleFactor *
                                                      12,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            FontAwesomeIcons.chevronDown,
                                            color: kBackgroundColor,
                                            size:
                                                SizeConfig.textScaleFactor * 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance',
                                    style: TextStyle(
                                      fontSize: SizeConfig.textScaleFactor * 12,
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  InkWell(
                                    onTap: _onSelectDistance,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: kBackgroundColor,
                                            width: 0.6,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${(_selectedRadius ~/ 1000).toInt()} km',
                                            style: Style.subtitle2.copyWith(
                                              color: kBackgroundColor,
                                              fontSize:
                                                  SizeConfig.textScaleFactor *
                                                      12,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            FontAwesomeIcons.chevronDown,
                                            color: kBackgroundColor,
                                            size:
                                                SizeConfig.textScaleFactor * 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sort by',
                                    style: TextStyle(
                                      fontSize: SizeConfig.textScaleFactor * 12,
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  InkWell(
                                    onTap: _onSortBy,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: kBackgroundColor,
                                            width: 0.6,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${_selectedSortBy[0].toUpperCase()}${_selectedSortBy.substring(1).toLowerCase()}',
                                            style: Style.subtitle2.copyWith(
                                              color: kBackgroundColor,
                                              fontSize:
                                                  SizeConfig.textScaleFactor *
                                                      12,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            FontAwesomeIcons.chevronDown,
                                            color: kBackgroundColor,
                                            size:
                                                SizeConfig.textScaleFactor * 12,
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
                    ],
                  ),
                ),
                ToggleSwitch(
                  activeBgColor: [kBackgroundColor],
                  initialLabelIndex: _selectedView == 'grid' ? 0 : 1,
                  minWidth: SizeConfig.screenWidth,
                  minHeight: 20.0,
                  borderColor: [Color(0xFFEBFBFF)],
                  totalSwitches: 2,
                  customTextStyles: [
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textScaleFactor * 15,
                      color: Colors.white,
                    ),
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textScaleFactor * 15,
                      color: Colors.white,
                    ),
                  ],
                  icons: [
                    Icons.grid_view,
                    Icons.map,
                  ],
                  inactiveFgColor: Colors.white60,
                  labels: [
                    'Grid',
                    'Map',
                  ],
                  onToggle: (index) {
                    setState(() {
                      _selectedView = index == 0 ? 'grid' : 'map';
                    });
                  },
                ),
                Expanded(
                  child: Container(
                      child: _selectedView == 'grid'
                          ? _buildGridView2()
                          : _buildMapView()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onSearchSubmitted(String? val) {
    if (val == null || val.isEmpty) return;

    _keywordTextController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          userid: widget.userId!,
          keyword: val,
        ),
      ),
    );
  }

  Widget _buildGridView2() {
    return SmartRefresher(
      onRefresh: () => _productBloc.add(GetFirstProducts(
        userid: application.currentUser!.uid,
        listType: widget.listType,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      )),
      controller: _refreshController,
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
            return FittedBox(
              child: BarterListItem(
                hideLikeBtn: widget.ownListing,
                product: product,
                onTapped: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      productId: product.productid ?? '',
                      ownItem: widget.ownListing ? true : false,
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

  _onSelectDistance() async {
    final distance = await showDialog<int?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search radius distance',
                        style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    // mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      ...radiusOptions.map(
                        (item) => ListTile(
                          title: Text((item ~/ 1000).toString() + ' km'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, item),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedRadius == item,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });

    if (distance != null) {
      lastProduct = null;
      setState(() {
        _selectedRadius = distance;
      });

      _productBloc.add(GetFirstProducts(
        userid: application.currentUser!.uid,
        listType: widget.listType,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      ));
    }
  }

  _onSortBy() async {
    final sortBy = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sort by',
                        style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    // mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      ...sortByOptions.map(
                        (item) => ListTile(
                          title: Text(item),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, item),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedSortBy.toLowerCase() ==
                              item.toLowerCase(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });

    if (sortBy != null) {
      lastProduct = null;
      setState(() {
        _selectedSortBy = sortBy;
      });

      _productBloc.add(GetFirstProducts(
        userid: application.currentUser!.uid,
        listType: widget.listType,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      ));
    }
  }

  _onFilterByCategory() async {
    if (_categoryList.isEmpty) return;
    final category = await showDialog<ProductCategoryModel?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              height: SizeConfig.screenHeight * .5,
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category',
                        style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      // mainAxisSize: MainAxisSize.min,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.0),
                        ListTile(
                          title: Text(
                            'All',
                            style: TextStyle(
                              fontSize: SizeConfig.textScaleFactor * 15.0,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, null),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedCategory == null,
                        ),
                        // ...(!(widget.listType == 'reco' &&
                        //             application.currentUserModel!.interests !=
                        //                 null &&
                        //             application.currentUserModel!.interests!
                        //                 .isNotEmpty)
                        //         ? _categoryList
                        //         : _categoryList.where((cat) => application
                        //             .currentUserModel!.interests!
                        //             .contains(cat.code)))
                        ..._categoryList.where((cat) => cat.type == 'PT1').map(
                              (item) => ListTile(
                                dense: true,
                                title: Text(
                                  item.name ?? '',
                                  style: TextStyle(
                                    fontSize: SizeConfig.textScaleFactor * 15.0,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                                onTap: () => Navigator.pop(context, item),
                                selectedColor: Color(0xFFBB3F03),
                                selected: _selectedCategory != null &&
                                    _selectedCategory!.code == item.code,
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });

    lastProduct = null;
    setState(() {
      _selectedCategory = category;
    });

    _productBloc.add(GetFirstProducts(
      userid: application.currentUser!.uid,
      listType: widget.listType,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
    ));
  }

  Future<dynamic> _onMarkerTapped(ProductModel product) async {
    print(product.address!.toJson());
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Color(0x79FFFFFF),
      barrierColor: Color(0x99000000),
      context: context,
      builder: (context) {
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                productId: product.productid ?? '',
                ownItem: widget.ownListing,
              ),
            ),
          ),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: SizeConfig.screenWidth * .25,
                      height: SizeConfig.screenWidth * .25,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: product.mediaPrimary != null
                              ? NetworkImage(product.mediaPrimary!.url!)
                              : AssetImage(
                                      'assets/images/image_placeholder.jpg')
                                  as ImageProvider<Object>,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.0),
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
                                  padding: EdgeInsets.only(
                                      right: i != 5 ? 5.0 : 0.0),
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
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    _buildMarkers();
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
          child: TapkatGoogleMap(
            showLocation: true,
            onCameraIdle: (latLng) => googleMapsCenter = latLng,
            initialLocation: googleMapsCenter ?? LatLng(1.3631246, 103.8325137),
            onCameraMove: (position) {
              _customInfoWindowController.onCameraMove!();
            },
            onTap: (latLng) {
              _customInfoWindowController.hideInfoWindow!();
            },
            onMapCreated: (controller) {
              googleMapsController = controller;
              _customInfoWindowController.googleMapController = controller;
            },
            centerMapOnMarkerTap: true,
            markers: _markers,
          ),
        ),
        CustomInfoWindow(
          controller: _customInfoWindowController,
          height: 70,
          width: 150,
          offset: 40,
        ),
      ],
    );
  }

  _buildMarkers() async {
    List<Marker> markers = [];

    await Future.forEach<ProductModel>(_list, (product) async {
      // var thumbnail = '';

      // if (product.mediaPrimary != null && product.mediaPrimary!.url_t != null) {
      //   thumbnail = product.mediaPrimary!.url_t!;
      // }

      // if (thumbnail.isEmpty &&
      //     product.media != null &&
      //     product.media!.isNotEmpty) {
      //   thumbnail = product.media!.first.url_t ?? '';
      // }
      // BitmapDescriptor? _bitmapDescriptor;
      // if (thumbnail.isEmpty) {
      //   _bitmapDescriptor = await BitmapDescriptor.fromAssetImage(
      //       ImageConfiguration(), 'assets/images/image_placeholder.jpg');
      // } else {
      //   final response = await get(Uri.parse(thumbnail));
      //   if (response.statusCode == 200) {
      //     _bitmapDescriptor = BitmapDescriptor.fromBytes(response.bodyBytes);
      //   }
      // }

      // if (_bitmapDescriptor != null) {
      //   markers.add(
      //     Marker(
      //       markerId: MarkerId(product.productid!),
      //       onTap: () => _onMarkerTapped(product),
      //       position: LatLng(
      //         product.address != null && product.address!.location != null
      //             ? product.address!.location!.latitude!.toDouble()
      //             : 0.00,
      //         product.address != null && product.address!.location != null
      //             ? product.address!.location!.longitude!.toDouble()
      //             : 0.00,
      //       ),
      //       icon: _bitmapDescriptor,
      //     ),
      //   );
      // }
      markers.add(
        Marker(
          markerId: MarkerId(product.productid!),
          onTap: () => _onMarkerTapped(product),
          position: LatLng(
            product.address != null && product.address!.location != null
                ? product.address!.location!.latitude!.toDouble()
                : 0.00,
            product.address != null && product.address!.location != null
                ? product.address!.location!.longitude!.toDouble()
                : 0.00,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(10.0),
        ),
      );
    });

    if (markers.isNotEmpty) {
      setState(() {
        _markers = List.from(markers);
      });
    }
  }

  _onSelectView() {
    setState(() {
      _selectedView = _selectedView != 'map' ? 'map' : 'grid';
    });
  }

  Expanded _buildSortOption() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.0),
          color: Colors.white,
        ),
        child: Center(
            child: Text(
          'Relevance',
          style: TextStyle(
            fontSize: 12.0,
          ),
        )),
      ),
    );
  }
}
