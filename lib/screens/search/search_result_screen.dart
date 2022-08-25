import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/bloc/search_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/utilities.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tapkat/utilities/application.dart' as application;

import 'package:label_marker/label_marker.dart';

class SearchResultScreen extends StatefulWidget {
  final String keyword;
  final String? category;
  final bool mapFirst;
  final String userid;
  final double initialRadius;
  const SearchResultScreen({
    Key? key,
    required this.keyword,
    this.category,
    this.mapFirst = false,
    required this.userid,
    this.initialRadius = 5000,
  }) : super(key: key);

  @override
  _SearchResultScreenState createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final _searchBloc = SearchBloc();
  final _homeBloc = HomeBloc();
  final _keyWordTextController = TextEditingController();
  List<ProductModel> searchResults = [];
  List<ProductMarkersRecord?> productMarkers = [];

  String _selectedView = 'grid'; //grid or map
  ProductCategoryModel? _selectedCategory;

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;

  StreamSubscription? _productMarkerStream;

  int currentPage = 0;

  ProductModel? lastProduct;
  ProductModel? lastUserProduct;

  final _productBloc = ProductBloc();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);
  final _refreshController = RefreshController();

  List<ProductCategoryModel> _categoryList = [];

  bool _loading = false;
  Set<Marker> _markers = {};

  bool zoomingByDrag = false;

  String _selectedSortBy = 'distance';
  List<String> sortByOptions = [
    'Distance',
    'Name',
    'Price',
    'Rating',
  ];
  double _selectedRadius = 5000;
  double mapZoomLevel = 11;

  Circle? _currentCircle;

  late LatLng _currentCenter;

  bool mapFirst = false;

  bool _loadingUserProducts = true;
  final _panelController = PanelController();
  bool _showYourItems = false;
  List<ProductModel> _myProductList = [];

  final _userItemsPagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  @override
  void initState() {
    mapFirst = widget.mapFirst;
    application.currentScreen = 'Search Result Screen';
    _keyWordTextController.text = widget.keyword;
    _productBloc.add(InitializeAddUpdateProduct());
    mapZoomLevel = getZoomLevel(_selectedRadius);
    _selectedRadius = widget.initialRadius;

    super.initState();

    setOriginalCenter();

    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: widget.category != null ? [widget.category!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      itemCount: _selectedView == 'map' ? 50 : 10,
      loc: _currentCenter,
    ));
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
    _productMarkerStream?.cancel();
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
    return Scaffold(
      body: ProgressHUD(
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
              bloc: _searchBloc,
              listener: (context, state) {
                if (state is SearchLoading) {
                  setState(() {
                    _loading = true;
                  });
                  ProgressHUD.of(context)!.show();
                } else {
                  setState(() {
                    _loading = false;
                  });
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is GetProductMarkersSuccess) {
                  _productMarkerStream = state.productMarkers.listen((list) {
                    setState(() {
                      productMarkers = list;
                    });
                  });
                }

                if (state is SearchNextProductsSuccess) {
                  print('hey ${state.list.length}');
                  if (state.list.isNotEmpty) {
                    searchResults.addAll(state.list);
                    _buildMarkers();
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

                if (state is SearchSuccess) {
                  _refreshController.refreshCompleted();
                  _pagingController.refresh();
                  lastProduct = null;

                  setState(() {
                    _markers.clear();
                    searchResults.clear();
                    _buildMarkers();
                  });

                  if (mapFirst) {
                    if (_selectedView != 'map') {
                      _onSelectView();
                    }
                    mapFirst = false;
                  }

                  if (state.searchResults.isNotEmpty) {
                    setState(() {
                      searchResults = state.searchResults;
                    });

                    if (state.searchResults.length ==
                        (_selectedView == 'map' ? 50 : 10)) {
                      _pagingController.appendPage(
                          state.searchResults, currentPage + 1);
                      lastProduct = state.searchResults.last;
                    } else {
                      _pagingController.appendLastPage(state.searchResults);
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
                        _searchBloc.add(
                          SearchNextProducts(
                            keyword: _keyWordTextController.text.trim(),
                            lastProductId: lastProduct!.productid!,
                            startAfterVal: startAfterVal,
                            category: widget.category,
                            sortBy: _selectedSortBy,
                            distance: _selectedRadius,
                          ),
                        );
                      }
                    });
                  } else {
                    setState(() {
                      _markers.clear();
                      searchResults.clear();
                      _buildMarkers();
                    });
                    if (_selectedRadius < 20000) {
                      _selectedRadius += 5000;
                      _searchBloc.add(InitializeSearch(
                        keyword: _keyWordTextController.text.trim(),
                        category:
                            widget.category != null ? [widget.category!] : null,
                        sortBy: _selectedSortBy,
                        distance: _selectedRadius,
                        itemCount: _selectedView == 'map' ? 50 : 10,
                        loc: _currentCenter,
                      ));
                    } else {
                      if (mounted) {
                        DialogMessage.show(
                          context,
                          message:
                              'No results found.\nTry to change your search criteria.',
                        );
                      }
                    }
                  }

                  _buildMarkers();
                }
              },
            ),
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) {
                if (state is InitializeAddUpdateProductSuccess) {
                  setState(() {
                    _categoryList = state.categories;
                    if (widget.category != null)
                      _selectedCategory = _categoryList
                          .firstWhere((cat) => cat.code == widget.category);
                  });
                  _productBloc.add(GetFirstUserItems());
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
                          lastProductId: lastUserProduct!.productid!,
                          startAfterVal: lastUserProduct!.price.toString(),
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
              },
            ),
          ],
          child: Container(
            width: SizeConfig.screenWidth,
            child: Column(
              children: [
                CustomAppBar(label: 'Search Products'),
                Expanded(
                  child: Container(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: CustomSearchBar(
                            controller: _keyWordTextController,
                            onSubmitted: (val) => _onSearchSubmitted(val),
                            backgroundColor: Color(0xFF005F73).withOpacity(0.3),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 8.0),
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: _selectedView != 'map' ? 2 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Category',
                                      style: TextStyle(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 12,
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
                                            Expanded(
                                              child: Text(
                                                _selectedCategory != null
                                                    ? _selectedCategory!.name!
                                                    : 'All',
                                                style: Style.subtitle2.copyWith(
                                                  color: kBackgroundColor,
                                                  fontSize: SizeConfig
                                                          .textScaleFactor *
                                                      12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              FontAwesomeIcons.chevronDown,
                                              color: kBackgroundColor,
                                              size: SizeConfig.textScaleFactor *
                                                  12,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              VerticalDivider(),
                              _buildDistanceWidget(),
                              VerticalDivider(),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sort by',
                                      style: TextStyle(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 12,
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
                                              size: SizeConfig.textScaleFactor *
                                                  12,
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
                              _searchBloc.add(InitializeSearch(
                                keyword: _keyWordTextController.text.trim(),
                                category: _selectedCategory != null
                                    ? [_selectedCategory!.code!]
                                    : null,
                                sortBy: _selectedSortBy,
                                distance: _selectedRadius,
                                itemCount: _selectedView == 'map' ? 50 : 10,
                                loc: _currentCenter,
                              ));
                              if (_productMarkerStream != null) {
                                _productMarkerStream!.cancel();
                                _productMarkerStream = null;
                              }
                            }
                          },
                        ),
                        Expanded(
                          child: _selectedView == 'map'
                              ? _buildMapView()
                              : searchResults.isNotEmpty
                                  ? Column(
                                      children: [
                                        Expanded(child: _buildGridView2()),
                                        SlidingUpPanel(
                                          isDraggable: true,
                                          controller: _panelController,
                                          backdropEnabled: false,
                                          minHeight:
                                              SizeConfig.screenHeight * 0.06,
                                          maxHeight:
                                              SizeConfig.screenHeight * 0.22,
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
                                                  horizontal: 15.0,
                                                  vertical: 5.0),
                                              color: Colors.white,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Your Items',
                                                    style: Style.subtitle2
                                                        .copyWith(
                                                      color: kBackgroundColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: TextDecoration
                                                          .underline,
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
                                                  onTap: () =>
                                                      _panelController.close(),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Your Items',
                                                        style: Style.subtitle2
                                                            .copyWith(
                                                          color:
                                                              kBackgroundColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _showYourItems
                                                            ? Icons
                                                                .arrow_drop_down
                                                            : Icons
                                                                .arrow_drop_up,
                                                        color: kBackgroundColor,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: PagedGridView<int,
                                                      ProductModel>(
                                                    pagingController:
                                                        _userItemsPagingController,
                                                    showNewPageProgressIndicatorAsGridChild:
                                                        false,
                                                    showNewPageErrorIndicatorAsGridChild:
                                                        false,
                                                    showNoMoreItemsIndicatorAsGridChild:
                                                        false,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 10.0,
                                                    ),
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 1,
                                                    ),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    builderDelegate:
                                                        PagedChildBuilderDelegate<
                                                            ProductModel>(
                                                      itemBuilder: (context,
                                                          product, index) {
                                                        var thumbnail = '';

                                                        if (product.media !=
                                                                null &&
                                                            product.media!
                                                                .isNotEmpty) {
                                                          for (var media
                                                              in product
                                                                  .media!) {
                                                            thumbnail =
                                                                media.url_t ??
                                                                    '';
                                                            if (thumbnail
                                                                .isNotEmpty)
                                                              break;
                                                          }
                                                        }

                                                        if (thumbnail.isEmpty) {
                                                          if (product.mediaPrimary != null &&
                                                              product.mediaPrimary!
                                                                      .url_t !=
                                                                  null &&
                                                              product
                                                                  .mediaPrimary!
                                                                  .url_t!
                                                                  .isNotEmpty)
                                                            thumbnail = product
                                                                .mediaPrimary!
                                                                .url_t!;
                                                        }
                                                        return LongPressDraggable(
                                                          data: product,
                                                          childWhenDragging:
                                                              Container(
                                                            height: SizeConfig
                                                                    .screenHeight *
                                                                0.12,
                                                            width: SizeConfig
                                                                    .screenHeight *
                                                                0.12,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  kBackgroundColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        20.0),
                                                                topRight: Radius
                                                                    .circular(
                                                                        20.0),
                                                              ),
                                                            ),
                                                          ),
                                                          feedback: Container(
                                                            height: 100.0,
                                                            width: 100.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              image:
                                                                  DecorationImage(
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
                                                                  await Navigator
                                                                      .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          ProductDetailsScreen(
                                                                    productId:
                                                                        product.productid ??
                                                                            '',
                                                                    ownItem:
                                                                        false,
                                                                  ),
                                                                ),
                                                              );

                                                              if (changed ==
                                                                  true) {
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
                                  : Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 30.0),
                                      child: Center(
                                        child: Text(
                                          'No products found',
                                          style: Style.subtitle2
                                              .copyWith(color: Colors.grey),
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

  Widget _buildDistanceWidget() {
    return Expanded(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _displayRadius(),
                    style: Style.subtitle2.copyWith(
                      color: kBackgroundColor,
                      fontSize: SizeConfig.textScaleFactor * 12,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    color: kBackgroundColor,
                    size: SizeConfig.textScaleFactor * 12,
                  ),
                ],
              ),
            ),
          ),
        ],
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

    _reset();

    setState(() {
      _selectedRadius = distance;
      _currentCircle = Circle(
        circleId: CircleId('radius'),
        center: _currentCenter,
        radius: _selectedRadius.toDouble(),
        strokeColor: kBackgroundColor,
        strokeWidth: 1,
        fillColor: kBackgroundColor.withOpacity(0.2),
      );
    });

    if (_selectedView == 'map') {
      double mapZoomLevel = getZoomLevel(_selectedRadius);

      googleMapsController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentCenter, zoom: mapZoomLevel),
      ));
    }

    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      itemCount: _selectedView == 'map' ? 50 : 10,
      loc: _currentCenter,
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

    if (sortBy == null) {
      return;
    }

    _reset();

    setState(() {
      _selectedSortBy = sortBy;
    });

    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      itemCount: _selectedView == 'map' ? 50 : 10,
      loc: _currentCenter,
    ));
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

    _reset();

    setState(() {
      _selectedCategory = category;
    });
    _searchBloc.add(
      InitializeSearch(
        keyword: _keyWordTextController.text.trim(),
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
        itemCount: _selectedView == 'map' ? 50 : 10,
        loc: _currentCenter,
      ),
    );
  }

  _reset() {
    lastProduct = null;
  }

  String _displayRadius() {
    final radius = _selectedRadius;
    final ave = ((radius / 1000) * 2).round() / 2;
    return '${ave.toStringAsFixed(2)} km';
  }

  double getZoomLevel(double diameter) {
    double zoomLevel = 11;
    double radius = diameter + diameter / 2;
    double scale = radius / 500;
    zoomLevel = (16 - log(scale) / log(2));

    final lat = application.currentUserLocation!.latitude!.toDouble();
    // final zoomLevel = log(38000 * cos(lat * pi / 180) / (radius / 1000)) + 3;
    final km = (34500 / pow(2, zoomLevel + 3) * cos(lat * pi / 180));

    print(
        'current radius: ${_selectedRadius / 1000}km || calculated zoom level: $zoomLevel || calculated km: $km');
    return zoomLevel;
  }

  Widget _buildMapView() {
    setState(() {
      mapZoomLevel = getZoomLevel(_selectedRadius.toDouble());
    });
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
      child: Stack(
        children: [
          Listener(
            onPointerDown: (e) {
              zoomingByDrag = true;
            },
            onPointerUp: (e) async {
              if (!e.down) {
                final zoomLevel = await googleMapsController.getZoomLevel();
                zoomingByDrag = false;
                print('user stopped dragging');
                final km = getRadiusFromZoomLevel(zoomLevel) / 10;

                final _km = km * 1000;

                print('0---> $zoomLevel & $mapZoomLevel');
                if ((_km >= 500 && _km <= 30000)) {
                  setState(() {
                    _selectedRadius = _km;

                    _currentCircle = Circle(
                      circleId: CircleId('radius'),
                      center: _currentCenter,
                      radius: _selectedRadius.toDouble(),
                      strokeColor: kBackgroundColor,
                      strokeWidth: 1,
                      fillColor: kBackgroundColor.withOpacity(0.2),
                    );
                  });
                  _reset();
                  _searchBloc.add(InitializeSearch(
                    keyword: _keyWordTextController.text.trim(),
                    category: _selectedCategory != null
                        ? [_selectedCategory!.code!]
                        : null,
                    sortBy: _selectedSortBy,
                    distance: _selectedRadius,
                    itemCount: _selectedView == 'map' ? 50 : 10,
                    loc: _currentCenter,
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
                  _currentCircle = Circle(
                    circleId: CircleId('radius'),
                    center: _currentCenter,
                    radius: _selectedRadius.toDouble(),
                    strokeColor: kBackgroundColor,
                    strokeWidth: 1,
                    fillColor: kBackgroundColor.withOpacity(0.2),
                  );
                });

                if (_selectedView == 'map') {
                  double mapZoomLevel = getZoomLevel(_selectedRadius);

                  googleMapsController
                      .animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(target: _currentCenter, zoom: mapZoomLevel),
                  ));
                }
              },
              onCameraIdle: (latLng) => googleMapsCenter = latLng,
              initialZoom: mapZoomLevel,
              initialLocation: LatLng(
                  application.currentUserLocation!.latitude!.toDouble(),
                  application.currentUserLocation!.longitude!.toDouble()),
              onMapCreated: (controller) {
                googleMapsController = controller;
              },
              showLocation: false,
              showZoomControls: false,
              markers: _markers.toSet(),
              onCameraMove: (camPos) {
                final km = getRadiusFromZoomLevel(camPos.zoom) / 10;
                print('====> $km');
              },
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
                mapZoomLevel = getZoomLevel(_selectedRadius.toDouble());
                googleMapsController
                    .animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: _currentCenter, zoom: mapZoomLevel + 2),
                ));

                _searchBloc.add(InitializeSearch(
                  keyword: _keyWordTextController.text.trim(),
                  category: _selectedCategory != null
                      ? [_selectedCategory!.code!]
                      : null,
                  sortBy: _selectedSortBy,
                  distance: _selectedRadius,
                  itemCount: _selectedView == 'map' ? 50 : 10,
                  loc: _currentCenter,
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
                      mapZoomLevel = getZoomLevel(_selectedRadius.toDouble());
                    } else {
                      mapZoomLevel =
                          await googleMapsController.getZoomLevel() + 1;
                    }

                    googleMapsController
                        .animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentCenter,
                        zoom: mapZoomLevel,
                      ),
                    ));

                    _searchBloc.add(InitializeSearch(
                      keyword: _keyWordTextController.text.trim(),
                      category: _selectedCategory != null
                          ? [_selectedCategory!.code!]
                          : null,
                      sortBy: _selectedSortBy,
                      distance: _selectedRadius,
                      itemCount: _selectedView == 'map' ? 50 : 10,
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
                      mapZoomLevel = getZoomLevel(_selectedRadius.toDouble());
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

                    _searchBloc.add(InitializeSearch(
                      keyword: _keyWordTextController.text.trim(),
                      category: _selectedCategory != null
                          ? [_selectedCategory!.code!]
                          : null,
                      sortBy: _selectedSortBy,
                      distance: _selectedRadius,
                      itemCount: _selectedView == 'map' ? 50 : 10,
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
    if (searchResults.isNotEmpty) {
      setState(
        () {
          searchResults.forEach(
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

  Widget _buildGridView2() {
    return SmartRefresher(
      onRefresh: () => _searchBloc.add(InitializeSearch(
        keyword: _keyWordTextController.text.trim(),
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
        itemCount: _selectedView == 'map' ? 50 : 10,
        loc: _currentCenter,
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
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          crossAxisCount: SizeConfig.screenWidth > 500 ? 3 : 2,
        ),
        builderDelegate: PagedChildBuilderDelegate<ProductModel>(
          itemBuilder: (context, product, index) {
            return DragTarget(
                builder: (context, candidateData, rejectedData) => FittedBox(
                      child: BarterListItem(
                        likeLeftMargin: 25,
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

  _onSelectView() {
    setState(() {
      _selectedView = _selectedView != 'map' ? 'map' : 'grid';
    });

    if (_selectedView == 'map') {
      setState(() {
        _selectedSortBy = 'distance';
      });
      _searchBloc.add(GetProductMarkers());
    } else {
      print('hey');
      _searchBloc.add(InitializeSearch(
        keyword: _keyWordTextController.text.trim(),
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
        itemCount: _selectedView == 'map' ? 50 : 10,
        loc: _currentCenter,
      ));
      if (_productMarkerStream != null) {
        _productMarkerStream!.cancel();
        _productMarkerStream = null;
      }
    }
  }

  double getRadiusFromZoomLevel(double zoomLevel) {
    final km = 34500 /
        pow(2, zoomLevel - 3) *
        cos(application.currentUserLocation!.latitude! * pi / 180);
    // print('km based on zoom level: $km');
    return km;
  }

  _onSearchSubmitted(String? val) {
    lastProduct = null;
    _pagingController.refresh();
    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
      itemCount: _selectedView == 'map' ? 50 : 10,
      loc: _currentCenter,
    ));
  }
}
