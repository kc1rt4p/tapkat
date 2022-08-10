import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/utilities.dart';
import 'package:tapkat/widgets/barter_list.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:toggle_switch/toggle_switch.dart';
import 'package:label_marker/label_marker.dart';

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
  final _homeBloc = HomeBloc();
  late String _title;
  List<ProductModel> _list = [];

  String _selectedView = 'grid'; //grid or map

  int currentPage = 0;

  List<ProductModel> indicators = [];

  late String initialView;

  final _keywordTextController = TextEditingController();

  final _refreshController = RefreshController();

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  ProductModel? lastProduct;
  ProductModel? lastUserProduct;

  bool _loading = false;
  Set<Marker> _markers = {};

  Circle? _currentCircle;

  String _selectedSortBy = 'distance';
  List<String> sortByOptions = [
    'Distance',
    'Name',
    'Price',
    'Rating',
  ];
  ProductCategoryModel? _selectedCategory;

  List<ProductCategoryModel> _categoryList = [];

  double _selectedRadius = 5000;
  double mapZoomLevel = 11;

  late LatLng _currentCenter;

  bool _loadingUserProducts = true;
  final _panelController = PanelController();
  bool _showYourItems = false;
  List<ProductModel> _myProductList = [];

  final _userItemsPagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  @override
  void initState() {
    application.currentScreen = 'Product List Screen';
    _setTitle();
    if (widget.initialView == 'map') {
      _selectedView = 'map';
    }

    _productBloc.add(InitializeAddUpdateProduct());
    _productBloc.add(GetFirstUserItems());
    super.initState();
    initialView = widget.initialView;
    setOriginalCenter();
  }

  void setOriginalCenter() {
    setState(() {
      _currentCenter = LatLng(
          application.currentUserLocation!.latitude!.toDouble(),
          application.currentUserLocation!.longitude!.toDouble());

      _currentCircle = Circle(
        circleId: CircleId('radius'),
        center: _currentCenter,
        radius: _selectedRadius.toDouble(),
        strokeColor: kBackgroundColor,
        strokeWidth: 1,
        fillColor: kBackgroundColor.withOpacity(0.2),
      );
    });
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
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _homeBloc,
              listener: (context, state) async {
                if (state is BarterDoesNotExist) {
                  final product = state.product1;
                  final product2 = state.product2;
                  final result =
                      await onQuickBarter(context, product, product2);
                  if (result == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarterScreen(
                        product: product,
                        initialOffer: product2,
                        quickBarter: result ? true : false,
                      ),
                    ),
                  );
                }

                if (state is BarterExists) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarterScreen(
                        product: state.product1,
                        initialOffer: state.product2,
                        existing: true,
                      ),
                    ),
                  );
                }
              },
            ),
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) {
                print('X=====> current product list state: $state');
                if (state is ProductLoading) {
                  setState(() {
                    _loading = true;
                    ProgressHUD.of(context)!.show();
                  });
                } else {
                  setState(() {
                    _loading = false;
                  });
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is InitializeAddUpdateProductSuccess) {
                  _categoryList = state.categories;

                  _productBloc.add(GetFirstProducts(
                    userid: application.currentUser!.uid,
                    loc: _currentCenter,
                    listType: widget.listType,
                    sortBy: _selectedSortBy,
                    distance: _selectedRadius,
                    category: _selectedCategory != null
                        ? [_selectedCategory!.code!]
                        : null,
                    itemCount: _selectedView == 'map' ? 50 : null,
                  ));
                }

                if (state is GetFirstProductsSuccess) {
                  _refreshController.refreshCompleted();
                  _pagingController.refresh();
                  lastProduct = null;
                  setState(() {
                    _list.clear();
                    _buildMarkers();
                  });

                  if (state.list.isNotEmpty) {
                    _list = state.list;
                    _buildMarkers();

                    final _productCount = (_selectedView == 'map') ? 50 : 10;

                    if (state.list.length == _productCount) {
                      currentPage += 1;
                      _pagingController.appendPage(state.list, currentPage);
                      lastProduct = state.list.last;
                    } else {
                      _pagingController.appendLastPage(state.list);
                    }
                  } else {
                    _pagingController.appendLastPage([]);
                    setState(() {
                      _list.clear();
                      _buildMarkers();
                    });

                    if (_selectedRadius < 20000) {
                      _selectedRadius += 5000;

                      _productBloc.add(
                        GetFirstProducts(
                          userid: application.currentUser!.uid,
                          loc: _currentCenter,
                          listType: widget.listType,
                          sortBy: _selectedSortBy,
                          distance: _selectedRadius,
                          category: _selectedCategory != null
                              ? [_selectedCategory!.code!]
                              : null,
                          itemCount: _selectedView == 'map' ? 50 : null,
                        ),
                      );
                    } else {
                      DialogMessage.show(
                        context,
                        message:
                            'No results found.\nTry to change your search criteria.',
                      );
                    }
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
                          userId:
                              widget.listType == 'user' ? widget.userId : '',
                          sortBy: _selectedSortBy,
                          distance: _selectedRadius,
                          category: _selectedCategory != null
                              ? [_selectedCategory!.code!]
                              : null,
                          itemCount: _selectedView == 'map' ? 50 : null,
                          loc: _currentCenter,
                        ),
                      );
                    }
                  });
                }

                if (state is GetFirstUserItemsSuccess) {
                  _userItemsPagingController.refresh();

                  if (state.list.isNotEmpty) {
                    lastUserProduct = state.list.last;
                    if (state.list.length == productCount) {
                      _userItemsPagingController.appendPage(
                          state.list, currentPage + 1);
                    } else {
                      _userItemsPagingController.appendLastPage(state.list);
                    }
                  } else {
                    _userItemsPagingController.appendLastPage([]);
                  }
                  _userItemsPagingController.addPageRequestListener((pageKey) {
                    if (lastUserProduct != null) {
                      _productBloc.add(
                        GetNextUserItems(
                          lastProductId: lastProduct!.productid!,
                          startAfterVal: lastProduct!.price.toString(),
                        ),
                      );
                    }
                  });
                }

                if (state is GetNextUserItemsSuccess) {
                  if (state.list.isNotEmpty) {
                    lastProduct = state.list.last;
                    if (state.list.length == productCount) {
                      _userItemsPagingController.appendPage(
                          state.list, currentPage + 1);
                    } else {
                      _userItemsPagingController.appendLastPage(state.list);
                    }
                  } else {
                    _userItemsPagingController.appendLastPage([]);
                  }
                }

                if (state is GetProductsSuccess) {
                  print('X=====> got next products');
                  if (state.list.isNotEmpty) {
                    _list.addAll(state.list);
                    _buildMarkers();
                    print('X=====> no. of all products: ${_list.length}');

                    final _productCount = (_selectedView == 'map') ? 50 : 10;
                    if (state.list.length == _productCount) {
                      currentPage += 1;
                      _pagingController.appendPage(state.list, currentPage);
                      lastProduct = state.list.last;
                      print('X=====> appended next page');
                    } else {
                      _pagingController.appendLastPage(state.list);
                      print('X=====> appended last page');
                    }
                  } else {
                    _pagingController.appendLastPage([]);
                  }
                }
              },
            ),
          ],
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
                                            _displayRadius(),
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
                                      color: _selectedView == 'map'
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  InkWell(
                                    onTap: _selectedView != 'map'
                                        ? _onSortBy
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: _selectedView == 'map'
                                                ? Colors.grey
                                                : kBackgroundColor,
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
                                              color: _selectedView != 'map'
                                                  ? kBackgroundColor
                                                  : Colors.grey,
                                              fontSize:
                                                  SizeConfig.textScaleFactor *
                                                      12,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            FontAwesomeIcons.chevronDown,
                                            color: _selectedView == 'map'
                                                ? Colors.grey
                                                : kBackgroundColor,
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

                    if (index == 1)
                      _buildMarkers();
                    else {
                      setOriginalCenter();
                      _productBloc.add(GetFirstProducts(
                        userid: application.currentUser!.uid,
                        loc: _currentCenter,
                        listType: widget.listType,
                        sortBy: _selectedSortBy,
                        distance: _selectedRadius,
                        category: _selectedCategory != null
                            ? [_selectedCategory!.code!]
                            : null,
                        itemCount: _selectedView == 'map' ? 50 : null,
                      ));
                    }
                  },
                ),
                Expanded(
                  child: Container(
                      child: _selectedView == 'grid'
                          ? Column(
                              children: [
                                Expanded(child: _buildGridView2()),
                                SlidingUpPanel(
                                  isDraggable: true,
                                  controller: _panelController,
                                  backdropEnabled: false,
                                  minHeight: SizeConfig.screenHeight * 0.06,
                                  maxHeight: SizeConfig.screenHeight * 0.22,
                                  onPanelClosed: () {
                                    setState(() {
                                      _showYourItems = false;
                                    });
                                    application.chatOpened = false;
                                  },
                                  onPanelOpened: () {
                                    setState(() {
                                      _showYourItems = true;
                                    });
                                    application.chatOpened = true;
                                  },
                                  collapsed: InkWell(
                                    onTap: () {
                                      _panelController.open();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 15.0, vertical: 5.0),
                                      color: Colors.white,
                                      child: Row(
                                        children: [
                                          Text(
                                            'Your Items',
                                            style: Style.subtitle2.copyWith(
                                              color: kBackgroundColor,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          Icon(
                                            _showYourItems
                                                ? Icons.arrow_drop_down
                                                : Icons.arrow_drop_up,
                                            color: kBackgroundColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  panel: Container(
                                    color: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 10.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () => _panelController.close(),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Your Items',
                                                style: Style.subtitle2.copyWith(
                                                  color: kBackgroundColor,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                              Icon(
                                                _showYourItems
                                                    ? Icons.arrow_drop_down
                                                    : Icons.arrow_drop_up,
                                                color: kBackgroundColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child:
                                              PagedGridView<int, ProductModel>(
                                            pagingController:
                                                _userItemsPagingController,
                                            showNewPageProgressIndicatorAsGridChild:
                                                false,
                                            showNewPageErrorIndicatorAsGridChild:
                                                false,
                                            showNoMoreItemsIndicatorAsGridChild:
                                                false,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10.0,
                                            ),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 1,
                                            ),
                                            scrollDirection: Axis.horizontal,
                                            builderDelegate:
                                                PagedChildBuilderDelegate<
                                                    ProductModel>(
                                              itemBuilder:
                                                  (context, product, index) {
                                                var thumbnail = '';

                                                if (product.media != null &&
                                                    product.media!.isNotEmpty) {
                                                  for (var media
                                                      in product.media!) {
                                                    thumbnail =
                                                        media.url_t ?? '';
                                                    if (thumbnail.isNotEmpty)
                                                      break;
                                                  }
                                                }

                                                if (thumbnail.isEmpty) {
                                                  if (product.mediaPrimary !=
                                                          null &&
                                                      product.mediaPrimary!
                                                              .url_t !=
                                                          null &&
                                                      product.mediaPrimary!
                                                          .url_t!.isNotEmpty)
                                                    thumbnail = product
                                                        .mediaPrimary!.url_t!;
                                                }
                                                return LongPressDraggable(
                                                  data: product,
                                                  childWhenDragging: Container(
                                                    height: SizeConfig
                                                            .screenHeight *
                                                        0.12,
                                                    width: SizeConfig
                                                            .screenHeight *
                                                        0.12,
                                                    decoration: BoxDecoration(
                                                      color: kBackgroundColor,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                20.0),
                                                        topRight:
                                                            Radius.circular(
                                                                20.0),
                                                      ),
                                                    ),
                                                  ),
                                                  feedback: Container(
                                                    height: 100.0,
                                                    width: 100.0,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: thumbnail
                                                                .isNotEmpty
                                                            ? CachedNetworkImageProvider(
                                                                thumbnail)
                                                            : AssetImage(
                                                                    'assets/images/image_placeholder.jpg')
                                                                as ImageProvider,
                                                      ),
                                                    ),
                                                  ),
                                                  child: BarterListItem(
                                                    height: SizeConfig
                                                            .screenHeight *
                                                        0.07,
                                                    width: SizeConfig
                                                            .screenHeight *
                                                        0.12,
                                                    hideLikeBtn: true,
                                                    hideDistance: true,
                                                    showRating: false,
                                                    product: product,
                                                    onTapped: () async {
                                                      final changed =
                                                          await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ProductDetailsScreen(
                                                            productId: product
                                                                    .productid ??
                                                                '',
                                                            ownItem: false,
                                                          ),
                                                        ),
                                                      );

                                                      if (changed == true) {
                                                        _productBloc.add(
                                                            InitializeAddUpdateProduct());
                                                      }
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildMapView()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayRadius() {
    final radius = _selectedRadius;
    final ave = ((radius / 1000) * 2).round() / 2;
    print('X---> $ave');
    return '${ave.toStringAsFixed(2)} km';
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
          mapFirst: widget.initialView == 'map',
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
          crossAxisCount: SizeConfig.screenWidth > 500 ? 3 : 2,
        ),
        builderDelegate: PagedChildBuilderDelegate<ProductModel>(
          itemBuilder: (context, product, index) {
            return DragTarget(
                builder: (context, candidateData, rejectedData) => FittedBox(
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
                    ),
                onAccept: (ProductModel product2) async {
                  if (product.userid != application.currentUser!.uid &&
                      product.status != 'completed' &&
                      product2.status != 'completed') {
                    _homeBloc.add(
                      CheckBarter(
                        product1: product,
                        product2: product2,
                      ),
                    );
                  }
                });
          },
        ),
      ),
    );
  }

  _onSelectDistance() async {
    final distance = await showDialog<double?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          double radiusSelected = _selectedRadius.toDouble();
          final radiusTextController = TextEditingController();
          radiusTextController.text =
              (radiusSelected / 1000).toStringAsFixed(2);
          return StatefulBuilder(builder: (context, StateSetter setState) {
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
                    SizedBox(height: 20.0),
                    TextFormField(
                      controller: radiusTextController,
                      autovalidateMode: AutovalidateMode.always,
                      decoration: InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                        suffixIcon: Text('km'),
                        suffixIconConstraints:
                            BoxConstraints(maxHeight: 50.0, maxWidth: 50.0),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null) {
                          if (val.isEmpty) return null;

                          final radius = double.parse(val.trim()) * 1000;

                          if (radius < 500 || radius > 30000) {
                            return 'Distance should be between 0.5km and 30km';
                          }
                        }

                        return null;
                      },
                      onChanged: (val) {
                        if (val.isEmpty) return;
                        final radius = double.parse(val) * 1000;
                        if (radius < 500 || radius > 30000) {
                          return;
                        } else {
                          setState(() {
                            radiusSelected = radius;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (radiusSelected > 1000) {
                                radiusSelected -= 500;
                              } else {
                                radiusSelected = 500;
                              }
                            });
                            print(radiusSelected);
                            radiusTextController.text =
                                (radiusSelected / 1000).toStringAsFixed(2);
                          },
                          child: Icon(Icons.remove, size: 20),
                        ),
                        SizedBox(width: 5.0),
                        Expanded(
                          child: Slider(
                            activeColor: kBackgroundColor,
                            thumbColor: kBackgroundColor,
                            value: radiusSelected,
                            onChanged: (val) {
                              setState(() {
                                radiusSelected = val;
                              });
                              radiusTextController.text =
                                  (radiusSelected / 1000).toStringAsFixed(2);
                            },
                            min: 0,
                            max: 30000,
                            divisions: 60,
                          ),
                        ),
                        SizedBox(width: 5.0),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (radiusSelected < 29500) {
                                radiusSelected += 500;
                              } else {
                                radiusSelected = 30000;
                              }
                            });
                            radiusTextController.text =
                                (radiusSelected / 1000).toStringAsFixed(2);
                          },
                          child: Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            removeMargin: true,
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context, null),
                            bgColor: kBackgroundColor,
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: CustomButton(
                            removeMargin: true,
                            label: 'Apply',
                            onTap: () => Navigator.pop(context, radiusSelected),
                            bgColor: Style.secondaryColor,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          });
        });

    if (distance == null) {
      return;
    }

    setState(() {
      _selectedRadius = distance;
      // _currentCircle = Circle(
      //   circleId: CircleId('radius'),
      //   center: _currentCenter,
      //   radius: _selectedRadius.toDouble(),
      //   strokeColor: kBackgroundColor,
      //   strokeWidth: 1,
      //   fillColor: kBackgroundColor.withOpacity(0.2),
      // );
    });

    if (_selectedView == 'map') {
      double mapZoomLevel = getZoomLevel(_selectedRadius);

      googleMapsController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentCenter, zoom: mapZoomLevel),
      ));
    }

    _productBloc.add(GetFirstProducts(
      userid: application.currentUser!.uid,
      loc: _currentCenter,
      listType: widget.listType,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      itemCount: _selectedView == 'map' ? 50 : null,
    ));
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
        itemCount: _selectedView == 'map' ? 50 : null,
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
      loc: _currentCenter,
      listType: widget.listType,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      itemCount: _selectedView == 'map' ? 50 : null,
    ));
  }

  double getZoomLevel(double diameter) {
    double zoomLevel = 11;
    double radius = diameter + diameter / 2;
    double scale = radius / 500;
    zoomLevel = (16 - log(scale) / log(2));

    final lat = application.currentUserLocation!.latitude!.toDouble();
    // final zoomLevel = log(38000 * cos(lat * pi / 180) / (radius / 1000)) + 3;
    final km = (38000 / pow(2, zoomLevel + 3) * cos(lat * pi / 180));

    print(
        'current radius: ${_selectedRadius / 1000}km || calculated zoom level: $zoomLevel || calculated km: $km');
    return zoomLevel;
  }

  Widget _buildMapView() {
    setState(() {
      mapZoomLevel = getZoomLevel(_selectedRadius);
    });
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
      child: Stack(
        children: [
          Listener(
            onPointerUp: (e) async {
              if (!e.down) {
                final zoomLevel = await googleMapsController.getZoomLevel();
                final km = getRadiusFromZoomLevel(zoomLevel) / 10;

                final _km = km * 1000;

                if ((_km >= 500 && _km <= 30000)) {
                  setState(() {
                    _selectedRadius = _km;

                    // _currentCircle = Circle(
                    //   circleId: CircleId('radius'),
                    //   center: _currentCenter,
                    //   radius: _selectedRadius.toDouble(),
                    //   strokeColor: kBackgroundColor,
                    //   strokeWidth: 1,
                    //   fillColor: kBackgroundColor.withOpacity(0.2),
                    // );
                  });

                  _productBloc.add(GetFirstProducts(
                    userid: application.currentUser!.uid,
                    loc: _currentCenter,
                    listType: widget.listType,
                    sortBy: _selectedSortBy,
                    distance: _selectedRadius,
                    category: _selectedCategory != null
                        ? [_selectedCategory!.code!]
                        : null,
                    itemCount: _selectedView == 'map' ? 50 : null,
                  ));
                }
              }
            },
            child: TapkatGoogleMap(
              // circles: {
              //   _currentCircle!,
              // },
              onTap: (latLng) {
                setState(() {
                  _currentCenter = latLng;
                  // _currentCircle = Circle(
                  //   circleId: CircleId('radius'),
                  //   center: _currentCenter,
                  //   radius: _selectedRadius.toDouble(),
                  //   strokeColor: kBackgroundColor,
                  //   strokeWidth: 1,
                  //   fillColor: kBackgroundColor.withOpacity(0.2),
                  // );
                });

                if (_selectedView == 'map') {
                  double mapZoomLevel = getZoomLevel(_selectedRadius);

                  googleMapsController
                      .animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentCenter, zoom: mapZoomLevel),
                  ));
                }
              },
              onCameraMove: (camPos) {
                setState(() {
                  _currentCenter = camPos.target;
                });
              },
              onCameraIdle: (latLng) => googleMapsCenter = latLng,
              initialZoom: mapZoomLevel,
              initialLocation: _currentCenter,
              onMapCreated: (controller) {
                googleMapsController = controller;
              },
              showLocation: false,
              showZoomControls: false,
              markers: _markers.toSet(),
            ),
          ),
          Positioned(
            right: 5.0,
            top: 10.0,
            child: FloatingActionButton.small(
              backgroundColor: kBackgroundColor.withOpacity(0.7),
              onPressed: () {
                setOriginalCenter();
                setState(() {
                  _selectedRadius = 500;
                });
                mapZoomLevel = getZoomLevel(_selectedRadius);
                googleMapsController
                    .animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: _currentCenter, zoom: mapZoomLevel + 2),
                ));

                _productBloc.add(GetFirstProducts(
                  userid: application.currentUser!.uid,
                  loc: _currentCenter,
                  listType: widget.listType,
                  sortBy: _selectedSortBy,
                  distance: _selectedRadius,
                  category: _selectedCategory != null
                      ? [_selectedCategory!.code!]
                      : null,
                  itemCount: _selectedView == 'map' ? 50 : null,
                ));
              },
              child: Icon(
                Icons.my_location,
              ),
            ),
          ),
          Positioned(
            right: 15.0,
            bottom: 30.0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      if (_selectedRadius > 500) {
                        _selectedRadius -= 500;
                      } else if (_selectedRadius < 1000) {
                        _selectedRadius = 500;
                      }

                      if (_selectedView == 'map') {
                        _currentCircle = Circle(
                          circleId: CircleId('radius'),
                          center: _currentCenter,
                          radius: _selectedRadius.toDouble(),
                          strokeColor: kBackgroundColor,
                          strokeWidth: 1,
                          fillColor: kBackgroundColor.withOpacity(0.2),
                        );
                      }
                    });

                    double mapZoomLevel = 0;
                    if (_selectedRadius > 500 && _selectedRadius < 30000) {
                      mapZoomLevel = getZoomLevel(_selectedRadius);
                    } else {
                      mapZoomLevel =
                          await googleMapsController.getZoomLevel() + 1;
                    }

                    googleMapsController
                        .animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target: _currentCenter, zoom: mapZoomLevel),
                    ));

                    _productBloc.add(GetFirstProducts(
                      userid: application.currentUser!.uid,
                      listType: widget.listType,
                      sortBy: _selectedSortBy,
                      distance: _selectedRadius,
                      category: _selectedCategory != null
                          ? [_selectedCategory!.code!]
                          : null,
                      itemCount: _selectedView == 'map' ? 50 : null,
                      loc: _currentCenter,
                    ));
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Icon(
                      FontAwesomeIcons.plus,
                      size: 22,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.black,
                  height: 1,
                ),
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      if (_selectedRadius < 30000) {
                        _selectedRadius += 500;
                      } else if (_selectedRadius > 30000) {
                        _selectedRadius = 30000;
                      }

                      if (_selectedView == 'map') {
                        _currentCircle = Circle(
                          circleId: CircleId('radius'),
                          center: _currentCenter,
                          radius: _selectedRadius.toDouble(),
                          strokeColor: kBackgroundColor,
                          strokeWidth: 1,
                          fillColor: kBackgroundColor.withOpacity(0.2),
                        );
                      }
                    });
                    double mapZoomLevel = 0;
                    if (_selectedRadius > 500 && _selectedRadius < 30000) {
                      mapZoomLevel = getZoomLevel(_selectedRadius);
                    } else {
                      mapZoomLevel =
                          await googleMapsController.getZoomLevel() - 1;
                    }
                    googleMapsController
                        .animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentCenter,
                        zoom: mapZoomLevel,
                      ),
                    ));

                    _productBloc.add(GetFirstProducts(
                      userid: application.currentUser!.uid,
                      listType: widget.listType,
                      sortBy: _selectedSortBy,
                      distance: _selectedRadius,
                      category: _selectedCategory != null
                          ? [_selectedCategory!.code!]
                          : null,
                      itemCount: _selectedView == 'map' ? 50 : null,
                      loc: _currentCenter,
                    ));
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Icon(
                      FontAwesomeIcons.minus,
                      size: 22,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildMarkers() async {
    if (_list.isNotEmpty) {
      setState(
        () {
          _list.forEach(
            (product) {
              _markers
                  .addLabelMarker(
                    LabelMarker(
                      onTap: () => onMarkerTapped(context, product),
                      label: product.productname != null
                          ? '${product.productname!.trim()}'
                          : '',
                      markerId: MarkerId(product.productid!),
                      position: LatLng(
                        product.address != null &&
                                product.address!.location != null
                            ? product.address!.location!.latitude!.toDouble()
                            : 0.00,
                        product.address != null &&
                                product.address!.location != null
                            ? product.address!.location!.longitude!.toDouble()
                            : 0.00,
                      ),
                      backgroundColor: kBackgroundColor,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 27.0,
                        letterSpacing: 1.0,
                        fontFamily: 'Poppins',
                        leadingDistribution: TextLeadingDistribution.even,
                        inherit: false,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                  )
                  .then(
                    (value) => setState(() {}),
                  );
            },
          );
        },
      );
    } else {
      setState(() {
        _markers.clear();
      });
    }

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(application.currentUser!.uid),
        position: _currentCenter,
      ));
    });

    // if (markers.isNotEmpty) {
    //   setState(() {
    //     _markers = markers;
    //   });
    // }
  }

  double getRadiusFromZoomLevel(double zoomLevel) {
    final km = 34500 /
        pow(2, zoomLevel - 3) *
        cos(application.currentUserLocation!.latitude! * pi / 180);
    // print('km based on zoom level: $km');
    return km;
  }

  // _onSelectView() {
  //   setState(() {
  //     _selectedView = _selectedView != 'map' ? 'map' : 'grid';
  //   });

  //   if (_selectedView == 'map') {
  //     _buildMarkers();
  //     _selectedSortBy = 'distance';
  //   }
  // }

  // Expanded _buildSortOption() {
  //   return Expanded(
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(9.0),
  //         color: Colors.white,
  //       ),
  //       child: Center(
  //           child: Text(
  //         'Relevance',
  //         style: TextStyle(
  //           fontSize: 12.0,
  //         ),
  //       )),
  //     ),
  //   );
  // }
}
