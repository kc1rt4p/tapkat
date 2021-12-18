import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/helper.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/barter_list.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeBloc = HomeBloc();
  late AuthBloc _authBloc;
  List<dynamic> _recommendedList = [];
  List<dynamic> _trendingList = [];
  List<dynamic> _myProductList = [];

  final _keywordTextController = TextEditingController();

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
    return ProgressHUD(
      indicatorColor: kBackgroundColor,
      backgroundColor: Colors.white,
      child: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _homeBloc,
            listener: (context, state) {
              if (state is HomeLoading) {
                ProgressHUD.of(context)!.show();
              } else {
                ProgressHUD.of(context)!.dismiss();
              }

              if (state is HomeScreenInitialized) {
                setState(() {
                  _recommendedList = state.recommended;
                  _trendingList = state.trending;
                  _myProductList = state.yourItems;
                });
              }
            },
          ),
          BlocListener(
            bloc: _authBloc,
            listener: (context, state) {
              if (state is GetCurrentUsersuccess) {
                _homeBloc.add(InitializeHomeScreen());
                setState(() {
                  _user = state.user;
                });
              }
            },
            child: Container(),
          )
        ],
        child: Column(
          children: [
            Container(
              color: kBackgroundColor,
              padding: EdgeInsets.only(top: SizeConfig.paddingTop),
              child: Column(
                children: [
                  CustomSearchBar(
                    controller: _keywordTextController,
                    onSubmitted: (val) => _onSearchSubmitted(val),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: double.maxFinite,
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(15.0, 20, 15.0, 0.0),
                decoration: BoxDecoration(
                  color: Color(0xFFEBFBFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BarterList(
                        context: context,
                        items: _recommendedList.map((product) {
                          final productName =
                              getJsonField(product, r'''$.productname''')
                                  .toString();

                          final price = getPriceWithCurrency(
                                  getJsonField(product, r'''$.price''')
                                      .toString())
                              .maybeHandleOverflow(
                            maxChars: 12,
                            replacement: '…',
                          );

                          final productId =
                              getJsonField(product, r'''$.productid''')
                                  .toString();

                          final imgUrl = getJsonField(
                                  product, r'''$.media_primary.url''') ??
                              'https://storage.googleapis.com/map-surf-assets/noimage.jpg';

                          final desc =
                              getJsonField(product, r'''$.productdesc''')
                                  .toString()
                                  .maybeHandleOverflow(
                                    replacement: '…',
                                  );
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
                          final address =
                              (product as Map<String, dynamic>)['address'];
                          final likes = getJsonField(product, r'''$.likes''')
                              .toString()
                              .maybeHandleOverflow(
                                replacement: '…',
                              );

                          return BarterListItem(
                            itemName: productName,
                            itemPrice: price,
                            imageUrl: imgUrl,
                            onTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  productId: productId,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        label: 'Recommended For You',
                      ),
                      BarterList(
                        context: context,
                        items: _trendingList.map((product) {
                          final productName =
                              getJsonField(product, r'''$.productname''')
                                  .toString();

                          final price = getPriceWithCurrency(
                                  getJsonField(product, r'''$.price''')
                                      .toString())
                              .maybeHandleOverflow(
                            maxChars: 12,
                            replacement: '…',
                          );

                          final productId =
                              getJsonField(product, r'''$.productid''')
                                  .toString();

                          final imgUrl = getJsonField(
                                  product, r'''$.media_primary.url''') ??
                              'https://storage.googleapis.com/map-surf-assets/noimage.jpg';

                          final desc =
                              getJsonField(product, r'''$.productdesc''')
                                  .toString()
                                  .maybeHandleOverflow(
                                    replacement: '…',
                                  );

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
                          final address =
                              (product as Map<String, dynamic>)['address'];

                          getJsonField(product, r'''$.address''')
                              .toString()
                              .maybeHandleOverflow(
                                replacement: '…',
                              );
                          final likes = getJsonField(product, r'''$.likes''')
                              .toString()
                              .maybeHandleOverflow(
                                replacement: '…',
                              );

                          return BarterListItem(
                            itemName: productName,
                            itemPrice: price,
                            imageUrl: imgUrl,
                            onTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  productId: productId,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        label: 'People are Looking For',
                      ),
                      BarterList(
                        context: context,
                        ownList: true,
                        items: _myProductList.map((product) {
                          final productName =
                              getJsonField(product, r'''$.productname''')
                                  .toString();

                          final price = getPriceWithCurrency(
                                  getJsonField(product, r'''$.price''')
                                      .toString())
                              .maybeHandleOverflow(
                            maxChars: 12,
                            replacement: '…',
                          );

                          final desc =
                              getJsonField(product, r'''$.productdesc''')
                                  .toString()
                                  .maybeHandleOverflow(
                                    replacement: '…',
                                  );

                          final productId =
                              getJsonField(product, r'''$.productid''')
                                  .toString();

                          final imgUrl = getJsonField(
                                  product, r'''$.media_primary.url''') ??
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
                          final address =
                              (product as Map<String, dynamic>)['address'];
                          final likes = getJsonField(product, r'''$.likes''')
                              .toString()
                              .maybeHandleOverflow(
                                replacement: '…',
                              );

                          return BarterListItem(
                            itemName: productName,
                            itemPrice: price,
                            imageUrl: imgUrl,
                            onTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  ownItem: true,
                                  productId: productId,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        label: 'Your Items',
                        smallItems: true,
                        removeMargin: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
}
