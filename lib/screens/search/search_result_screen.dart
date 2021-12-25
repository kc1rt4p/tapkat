import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/search/bloc/search_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/helper.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';

class SearchResultScreen extends StatefulWidget {
  final String keyword;
  const SearchResultScreen({
    Key? key,
    required this.keyword,
  }) : super(key: key);

  @override
  _SearchResultScreenState createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final _searchBloc = SearchBloc();
  final _keyWordTextController = TextEditingController();
  List<dynamic> searchResults = [];
  List<ProductMarkersRecord?> productMarkers = [];

  String _selectedView = 'grid'; //grid or map

  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  StreamSubscription? _productMarkerStream;

  int currentPage = 0;

  @override
  void initState() {
    _searchBloc.add(InitializeSearch(widget.keyword));
    _keyWordTextController.text = widget.keyword;
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
          bloc: _searchBloc,
          listener: (context, state) {
            if (state is SearchLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetProductMarkersSuccess) {
              _productMarkerStream = state.productMarkers.listen((list) {
                setState(() {
                  productMarkers = list;
                });
              });
            }

            if (state is SearchInitialized) {
              print(state.searchResults);
              setState(() {
                searchResults = state.searchResults;
              });
            }

            if (state is SearchSuccess) {
              print(state.searchResults);
              setState(() {
                searchResults = state.searchResults;
              });
            }
          },
          child: Container(
            width: SizeConfig.screenWidth,
            child: Column(
              children: [
                CustomAppBar(label: 'Explore'),
                Expanded(
                  child: Container(
                    child: Column(
                      children: [
                        CustomSearchBar(
                          controller: _keyWordTextController,
                          onSubmitted: (val) => _onSearchSubmitted(val),
                          backgroundColor: Color(0xFF005F73).withOpacity(0.3),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 8.0),
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Text(
                                'Search Results',
                                style: Style.subtitle2
                                    .copyWith(color: kBackgroundColor),
                              ),
                              Spacer(),
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
                        ),
                        Expanded(
                          child: Container(
                            child: searchResults.isNotEmpty
                                ? _selectedView == 'grid'
                                    ? _buildGridView()
                                    : _buildMapView()
                                : Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 30.0),
                                    child: Center(
                                      child: Text(
                                        'No products found',
                                        style: Style.subtitle2
                                            .copyWith(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                  height: SizeConfig.screenHeight * .06,
                  color: kBackgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _onPrevTapped,
                          child: Container(
                            child: Center(
                                child: Icon(
                              Icons.arrow_left,
                              size: 40.0,
                              color:
                                  currentPage == 0 ? Colors.grey : Colors.white,
                            )),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _onNextTapped,
                          child: Container(
                            child: Center(
                                child: Icon(
                              Icons.arrow_right,
                              size: 40.0,
                              color: Colors.white,
                            )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onNextTapped() {
    //
  }

  _onPrevTapped() {
    //
  }

  _buildMapView() {
    return Container(
      child: TapkatGoogleMap(
        controller: googleMapsController,
        onCameraIdle: (latLng) => googleMapsCenter = latLng,
        initialLocation: googleMapsCenter ?? LatLng(1.3631246, 103.8325137),
        markers: productMarkers
            .map(
              (productMarker) => TapkatMarker(
                productMarker!.reference!.path,
                productMarker.location,
                () async {
                  await showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Color(0x79FFFFFF),
                    barrierColor: Color(0x99000000),
                    context: context,
                    builder: (context) {
                      return Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              productMarker.productname ?? '',
                              style: Style.subtitle2
                                  .copyWith(color: kBackgroundColor),
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              productMarker.price == null
                                  ? ''
                                  : '\$${productMarker.price!.toStringAsFixed(2)}',
                              style: Style.subtitle2.copyWith(
                                  color: kBackgroundColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }

  GridView _buildGridView() {
    return GridView.count(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      crossAxisCount: 2,
      mainAxisSpacing: 10.0,
      crossAxisSpacing: 10.0,
      children: searchResults.map((product) {
        final productName =
            getJsonField(product, r'''$.productname''').toString();

        final price = getPriceWithCurrency(
                getJsonField(product, r'''$.price''').toString())
            .maybeHandleOverflow(
          maxChars: 12,
          replacement: '…',
        );

        final desc = getJsonField(product, r'''$.productdesc''')
            .toString()
            .maybeHandleOverflow(
              replacement: '…',
            );

        final productId = getJsonField(product, r'''$.productid''').toString();

        final imgUrl = getJsonField(product, r'''$.media_primary.url''') ??
            'https://storage.googleapis.com/map-surf-assets/noimage.jpg';

        final owner = getJsonField(product, r'''$.userid''')
            .toString()
            .maybeHandleOverflow(
              replacement: '…',
            );
        final rating = getJsonField(product, r'''$.rating''')
            .toString()
            .maybeHandleOverflow(
              replacement: '…',
            );
        final address = (product as Map<String, dynamic>)['address'];
        final likes = getJsonField(product, r'''$.likes''')
            .toString()
            .maybeHandleOverflow(
              replacement: '…',
            );
        return Center(
          child: BarterListItem(
            itemName: productName,
            itemPrice: price,
            imageUrl: imgUrl,
            onTapped: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  ownItem: false,
                  productId: productId,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    if (val == null || val.isEmpty) return;
    _searchBloc.add(InitializeSearch(val));
  }
}
