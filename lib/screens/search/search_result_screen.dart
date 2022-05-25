import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/search/bloc/search_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
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
  const SearchResultScreen({
    Key? key,
    required this.keyword,
    this.category,
    this.mapFirst = false,
    required this.userid,
  }) : super(key: key);

  @override
  _SearchResultScreenState createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final _searchBloc = SearchBloc();
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

  final _productBloc = ProductBloc();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);
  final _refreshController = RefreshController();

  List<ProductCategoryModel> _categoryList = [];

  bool _loading = false;
  Set<Marker> _markers = {};

  String _selectedSortBy = 'distance';
  List<String> sortByOptions = [
    'Distance',
    'Name',
    'Price',
    'Rating',
  ];
  int _selectedRadius = 5000;
  List<int> radiusOptions = [1000, 5000, 10000, 20000, 50000];

  @override
  void initState() {
    application.currentScreen = 'Search Result Screen';
    _keyWordTextController.text = widget.keyword;
    _productBloc.add(InitializeAddUpdateProduct());

    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: widget.category != null ? [widget.category!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
    ));
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _productMarkerStream?.cancel();
    super.dispose();
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
                  if (state.searchResults.isNotEmpty) {
                    lastProduct = state.searchResults.last;
                    searchResults.addAll(state.searchResults);
                    if (state.searchResults.length == productCount) {
                      _pagingController.appendPage(
                          state.searchResults, currentPage + 1);
                    } else {
                      _pagingController.appendLastPage(state.searchResults);
                    }

                    if (widget.mapFirst) {
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
                  }
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
                                flex: 2,
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
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 12,
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
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sort by',
                                      style: TextStyle(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 12,
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
                          },
                        ),
                        Expanded(
                          child: searchResults.isNotEmpty
                              ? _selectedView == 'grid'
                                  ? _buildGridView2()
                                  : _buildMapView()
                              : !_loading
                                  ? Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 30.0),
                                      child: Center(
                                        child: Text(
                                          'No products found',
                                          style: Style.subtitle2
                                              .copyWith(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  : Container(),
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

    if (distance == null) {
      return;
    }

    _reset();

    setState(() {
      _selectedRadius = distance;
    });

    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
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

    if (sortBy != null) {
      setState(() {
        _selectedSortBy = sortBy;
      });

      _searchBloc.add(InitializeSearch(
        keyword: _keyWordTextController.text.trim(),
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
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
      ),
    );
  }

  _reset() {
    lastProduct = null;
  }

  _buildMapView() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
      child: TapkatGoogleMap(
        onCameraIdle: (latLng) => googleMapsCenter = latLng,
        initialLocation: googleMapsCenter ?? LatLng(1.3631246, 103.8325137),
        onMapCreated: (controller) {
          googleMapsController = controller;
          _buildMarkers();
        },
        markers: _markers.toSet(),
      ),
    );
  }

  _buildMarkers() async {
    searchResults.forEach((product) {
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

  Widget _buildGridView2() {
    return SmartRefresher(
      onRefresh: () => _searchBloc.add(InitializeSearch(
        keyword: _keyWordTextController.text.trim(),
        category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
        sortBy: _selectedSortBy,
        distance: _selectedRadius,
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
          crossAxisCount: 2,
        ),
        builderDelegate: PagedChildBuilderDelegate<ProductModel>(
          itemBuilder: (context, product, index) {
            return FittedBox(
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
            );
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
      _searchBloc.add(GetProductMarkers());
    } else {
      if (_productMarkerStream != null) {
        _productMarkerStream!.cancel();
        _productMarkerStream = null;
      }
    }
  }

  _onSearchSubmitted(String? val) {
    lastProduct = null;
    _pagingController.refresh();
    _searchBloc.add(InitializeSearch(
      keyword: _keyWordTextController.text.trim(),
      category: _selectedCategory != null ? [_selectedCategory!.code!] : null,
      sortBy: _selectedSortBy,
      distance: _selectedRadius,
    ));
  }
}
