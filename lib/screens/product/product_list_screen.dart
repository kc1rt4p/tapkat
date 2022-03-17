import 'package:clippy_flutter/clippy_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
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

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;
  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  ProductModel? lastProduct;

  @override
  void initState() {
    _setTitle();
    _productBloc.add(GetFirstProducts(widget.listType, userId: widget.userId));

    super.initState();
    setState(() {
      _selectedView = widget.initialView;
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
            print('CURRENT STATE');
            // if (state is ProductLoading) {
            //   ProgressHUD.of(context)!.show();
            // } else {
            //   ProgressHUD.of(context)!.dismiss();
            // }

            if (state is GetFirstProductsSuccess) {
              // setState(() {
              //   currentPage = 0;
              //   _list = state.list;
              //   indicators.clear();
              //   if (_list.isNotEmpty) {
              //     indicators.add(_list.last);
              //   }
              // });
              if (state.list.isNotEmpty) {
                lastProduct = state.list.last;
                if (state.list.length == productCount) {
                  setState(() {
                    _list.addAll(state.list);
                  });
                  _pagingController.appendPage(state.list, currentPage + 1);
                } else {
                  setState(() {
                    _list.addAll(state.list);
                  });
                  _pagingController.appendLastPage(state.list);
                }
              } else {
                print('lastrProduct name: ${lastProduct!.productname}');
                _pagingController.addPageRequestListener((pageKey) {
                  if (lastProduct != null) {
                    _productBloc.add(
                      GetNextProducts(
                        listType: widget.listType,
                        lastProductId: lastProduct!.productid!,
                        startAfterVal: lastProduct!.price!.toString(),
                        userId: widget.listType == 'user' ? widget.userId : '',
                      ),
                    );
                  }
                });
              }

              print('lastrProduct name: ${lastProduct!.productname}');
              _pagingController.addPageRequestListener((pageKey) {
                if (lastProduct != null) {
                  _productBloc.add(
                    GetNextProducts(
                      listType: widget.listType,
                      lastProductId: lastProduct!.productid!,
                      startAfterVal: lastProduct!.price!.toString(),
                      userId: widget.listType == 'user' ? widget.userId : '',
                    ),
                  );
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
                Row(
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        margin: EdgeInsets.symmetric(horizontal: 20.0),
                        controller: _keywordTextController,
                        backgroundColor: Color(0xFF005F73).withOpacity(0.3),
                        onSubmitted: (val) => _onSearchSubmitted(val),
                      ),
                    ),
                    Visibility(
                      visible: !widget.ownListing,
                      child: Row(
                        children: [
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
                          SizedBox(width: 20.0),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text('Sort by:'),
                      SizedBox(width: 5.0),
                      _buildSortOption(),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9.0),
                              color: Colors.white),
                          child: Center(
                              child: Text(
                            'Most Recent',
                            style: TextStyle(
                              fontSize: 12.0,
                            ),
                          )),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9.0),
                              color: Colors.white),
                          child: Row(
                            children: [
                              Text(
                                'Price',
                                style: TextStyle(
                                  fontSize: 12.0,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 14.0,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                      child: _selectedView == 'grid'
                          ? _buildGridView2()
                          : _buildMapView()
                      // _list.isNotEmpty
                      //     ?
                      //     : Container(
                      //         padding: EdgeInsets.symmetric(horizontal: 30.0),
                      //         child: Center(
                      //           child: Column(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             children: [
                      //               Text(
                      //                 'No products found',
                      //                 style: Style.subtitle2
                      //                     .copyWith(color: Colors.grey),
                      //               ),
                      //               SizedBox(height: 16.0),
                      //               Visibility(
                      //                 visible:
                      //                     widget.showAdd && widget.ownListing,
                      //                 child: Padding(
                      //                   padding: const EdgeInsets.symmetric(
                      //                       horizontal: 30.0),
                      //                   child: CustomButton(
                      //                     label: 'Add Product',
                      //                     onTap: () => Navigator.push(
                      //                       context,
                      //                       MaterialPageRoute(
                      //                         builder: (context) =>
                      //                             ProductAddScreen(),
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ),
                      ),
                ),
                // Container(
                //   width: double.infinity,
                //   padding:
                //       EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                //   height: SizeConfig.screenHeight * .06,
                //   color: kBackgroundColor,
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     children: [
                //       Expanded(
                //         child: InkWell(
                //           onTap: _onPrevTapped,
                //           child: Container(
                //             child: Center(
                //                 child: Icon(
                //               Icons.arrow_left,
                //               size: 40.0,
                //               color:
                //                   currentPage == 0 ? Colors.grey : Colors.white,
                //             )),
                //           ),
                //         ),
                //       ),
                //       Expanded(
                //         child: InkWell(
                //           onTap: _onNextTapped,
                //           child: Container(
                //             child: Center(
                //               child: Icon(
                //                 Icons.arrow_right,
                //                 size: 40.0,
                //                 color:
                //                     _list.isEmpty ? Colors.grey : Colors.white,
                //               ),
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
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
          keyword: val,
        ),
      ),
    );
  }

  Widget _buildGridView2() {
    return PagedGridView<int, ProductModel>(
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
          var thumbnail = '';

          if (product.mediaPrimary != null &&
              product.mediaPrimary!.url != null &&
              product.mediaPrimary!.url!.isNotEmpty)
            thumbnail = product.mediaPrimary!.url!;

          if (product.mediaPrimary != null &&
              product.mediaPrimary!.url_t != null &&
              product.mediaPrimary!.url_t!.isNotEmpty)
            thumbnail = product.mediaPrimary!.url_t!;

          if (product.mediaPrimary == null ||
              product.mediaPrimary!.url!.isEmpty &&
                  product.mediaPrimary!.url_t!.isEmpty &&
                  product.media != null &&
                  product.media!.isNotEmpty)
            thumbnail = product.media!.first.url_t != null
                ? product.media!.first.url_t!
                : product.media!.first.url!;
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

                  return BarterListItem(
                    height: SizeConfig.screenHeight * 0.23,
                    width: SizeConfig.screenWidth * 0.40,
                    hideLikeBtn: widget.ownListing,
                    liked: liked,
                    itemName: product.productname ?? '',
                    itemPrice: product.price != null
                        ? product.price!.toStringAsFixed(2)
                        : '0',
                    imageUrl: thumbnail,
                    onTapped: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(
                          productId: product.productid ?? '',
                          ownItem: widget.ownListing ? true : false,
                        ),
                      ),
                    ),
                    onLikeTapped: () {
                      if (record != null) {
                        final newData = createUserLikesRecordData(
                          liked: !record.liked!,
                        );

                        record.reference!.update(newData);
                        if (liked) {
                          _productBloc.add(
                            Unlike(product),
                          );
                        } else {
                          _productBloc.add(AddLike(product));
                        }
                      }
                    },
                  );
                }),
          );
        },
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
                          ownItem: widget.ownListing,
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

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(
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
              // _list.forEach((product) {
              //   googleMapsController
              //       .showMarkerInfoWindow(MarkerId(product.productid!));
              // });
              _customInfoWindowController.googleMapController = controller;
              _list.forEach((product) async {
                await Future.delayed(Duration(milliseconds: 500), () {
                  _customInfoWindowController.addInfoWindow!(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: kBackgroundColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                product.productname ?? '',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                product.price == null
                                    ? ''
                                    : '\$ ${product.price!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Triangle.isosceles(
                          edge: Edge.BOTTOM,
                          child: Container(
                            color: kBackgroundColor,
                            width: 20.0,
                            height: 10.0,
                          ),
                        ),
                      ],
                    ),
                    gmf.LatLng(
                      product.address != null &&
                              product.address!.location != null
                          ? product.address!.location!.latitude!.toDouble()
                          : 0.00,
                      product.address != null &&
                              product.address!.location != null
                          ? product.address!.location!.longitude!.toDouble()
                          : 0.00,
                    ),
                  );
                });
              });
            },
            markers: _list
                .map(
                  (product) => TapkatMarker(
                      product.productid!,
                      LatLng(
                        product.address != null &&
                                product.address!.location != null
                            ? product.address!.location!.latitude!.toDouble()
                            : 0.00,
                        product.address != null &&
                                product.address!.location != null
                            ? product.address!.location!.longitude!.toDouble()
                            : 0.00,
                      ),
                      () => _onMarkerTapped(product),
                      product),
                )
                .toList(),
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

  void _onNextTapped() {
    print('next tapped, current page $currentPage');
    if (_list.isEmpty) return;

    _productBloc.add(
      GetNextProducts(
        listType: widget.listType,
        lastProductId: _list.last.productid!,
        startAfterVal: _list.last.price!.toString(),
        userId: widget.listType == 'user' ? widget.userId : '',
      ),
    );

    setState(() {
      currentPage += 1;
    });
  }

  void _onPrevTapped() {
    if (currentPage < 1) return;

    if (currentPage == 1) _productBloc.add(GetFirstProducts(widget.listType));

    if (currentPage > 1) {
      _productBloc.add(GetNextProducts(
          listType: widget.listType,
          lastProductId: indicators[currentPage - 2].productid!,
          startAfterVal: indicators[currentPage - 2].price!.toString()));
    }

    setState(() {
      currentPage -= 1;
    });
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
