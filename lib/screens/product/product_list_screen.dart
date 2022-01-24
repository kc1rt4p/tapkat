import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:tapkat/widgets/tapkat_map.dart';

class ProductListScreen extends StatefulWidget {
  final bool showAdd;

  final String listType;
  final String? userId;
  final bool ownListing;

  const ProductListScreen({
    Key? key,
    required this.listType,
    this.userId,
    this.showAdd = false,
    this.ownListing = false,
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

  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  @override
  void initState() {
    _setTitle();
    _productBloc.add(GetFirstProducts(widget.listType, userId: widget.userId));
    super.initState();
  }

  void _setTitle() {
    switch (widget.listType) {
      case 'reco':
        _title = 'Recommended For You';
        break;
      case 'demand':
        _title = 'People are Looking For';
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
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetFirstProductsSuccess) {
              setState(() {
                currentPage = 0;
                _list = state.list;
                indicators.clear();
                if (_list.isNotEmpty) {
                  indicators.add(_list.last);
                }
              });
            }

            if (state is GetProductsSuccess) {
              setState(() {
                _list = state.list;

                indicators.add(_list.last);
              });
              print('==== CURRENT PAGE: $currentPage');

              indicators.asMap().forEach(
                  (key, value) => print('==== page $key: ${value.productid}'));
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
                        controller: TextEditingController(),
                        backgroundColor: Color(0xFF005F73).withOpacity(0.3),
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
                    child: _list.isNotEmpty
                        ? _selectedView == 'grid'
                            ? _buildGridView()
                            : _buildMapView()
                        : Container(
                            padding: EdgeInsets.symmetric(horizontal: 30.0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No products found',
                                    style: Style.subtitle2
                                        .copyWith(color: Colors.grey),
                                  ),
                                  SizedBox(height: 16.0),
                                  Visibility(
                                    visible:
                                        widget.showAdd && widget.ownListing,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0),
                                      child: CustomButton(
                                        label: 'Add Product',
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductAddScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                color:
                                    _list.isEmpty ? Colors.grey : Colors.white,
                              ),
                            ),
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

  Widget _buildGridView() {
    return GridView.count(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      crossAxisCount: 2,
      mainAxisSpacing: 14.0,
      crossAxisSpacing: 12.0,
      children: _list
          .map((product) => Center(
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
                        if (snapshot.data != null &&
                            snapshot.data!.isNotEmpty) {
                          record = snapshot.data!.first;
                          if (record != null) {
                            liked = record.liked ?? false;
                          }
                        }
                      }

                      return BarterListItem(
                        hideLikeBtn: widget.ownListing,
                        liked: liked,
                        itemName: product.productname ?? '',
                        itemPrice: product.price != null
                            ? product.price!.toStringAsFixed(2)
                            : '0',
                        imageUrl: product.mediaPrimary != null
                            ? product.mediaPrimary!.url!
                            : '',
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
              ))
          .toList(),
    );
  }

  Widget _buildMapView() {
    return Container(
      child: TapkatGoogleMap(
        controller: googleMapsController,
        onCameraIdle: (latLng) => googleMapsCenter = latLng,
        initialLocation: googleMapsCenter ?? LatLng(1.3631246, 103.8325137),
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
                              product.productname ?? '',
                              style: Style.subtitle2
                                  .copyWith(color: kBackgroundColor),
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              product.price == null
                                  ? ''
                                  : '\$${product.price!.toStringAsFixed(2)}',
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
