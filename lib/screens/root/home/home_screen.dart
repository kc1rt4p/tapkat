import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/product/product_list_screen.dart';
import 'package:tapkat/screens/root/bloc/root_bloc.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
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
  final _productBloc = ProductBloc();
  late RootBloc _rootBloc;
  late AuthBloc _authBloc;
  List<ProductModel> _recommendedList = [];
  List<ProductModel> _trendingList = [];
  List<ProductModel> _myProductList = [];

  List<Map<String, dynamic>> _categoryProducts = [];

  final _keywordTextController = TextEditingController();

  bool _loadingRecoList = false;
  bool _loadingTrendingList = false;
  bool _loadingUserProducts = false;

  User? _user;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _rootBloc = BlocProvider.of<RootBloc>(context);
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      indicatorColor: kBackgroundColor,
      backgroundColor: Colors.white,
      barrierEnabled: false,
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

              if (state is GetProductCategoriesSuccess) {
                print('----- OHOY');
                setState(() {
                  _categoryProducts = state.list;
                });
              }
            },
          ),
          BlocListener(
            bloc: _homeBloc,
            listener: (context, state) {
              if (state is LoadedRecommendedList) {
                setState(() {
                  _recommendedList = state.recommended;
                  _recommendedList
                      .sort((a, b) => a.productname!.compareTo(b.productname!));
                  _loadingRecoList = false;
                });
              }

              if (state is LoadedTrendingList) {
                setState(() {
                  _trendingList = state.trending;
                  _trendingList
                      .sort((a, b) => a.productname!.compareTo(b.productname!));
                  _loadingTrendingList = false;
                });
              }

              if (state is LoadedUserList) {
                setState(() {
                  _loadingUserProducts = false;
                  _myProductList = state.yourItems;
                  _myProductList
                      .sort((a, b) => a.productname!.compareTo(b.productname!));
                });
              }

              if (state is LoadingUserList) {
                setState(() {
                  _loadingUserProducts = true;
                });
              }

              if (state is LoadingRecommendedList) {
                setState(() {
                  _loadingRecoList = true;
                });
              }

              if (state is LoadingTrendingList) {
                setState(() {
                  _loadingTrendingList = true;
                });
              }
            },
          ),
          BlocListener(
            bloc: _authBloc,
            listener: (context, state) {
              if (state is GetCurrentUsersuccess) {
                setState(() {
                  _user = state.user;
                });

                _homeBloc.add(InitializeHomeScreen());

                _productBloc.add(GetProductCategories());
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
                padding: EdgeInsets.fromLTRB(15.0, 15, 15.0, 0.0),
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
                        loading: _loadingRecoList,
                        context: context,
                        items: _recommendedList
                            .map((product) => _buildProductItem(
                                  product: product,
                                ))
                            .toList(),
                        label: 'Recommended For You',
                        onViewAllTapped: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              listType: 'reco',
                              showAdd: false,
                            ),
                          ),
                        ),
                        onMapBtnTapped: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              listType: 'reco',
                              showAdd: false,
                              initialView: 'map',
                            ),
                          ),
                        ),
                      ),
                      BarterList(
                        loading: _loadingTrendingList,
                        context: context,
                        items: _trendingList
                            .map((product) => _buildProductItem(
                                  product: product,
                                ))
                            .toList(),
                        label: 'What\'s Hot',
                        onViewAllTapped: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              listType: 'demand',
                              showAdd: false,
                            ),
                          ),
                        ),
                        onMapBtnTapped: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              listType: 'demand',
                              showAdd: false,
                              initialView: 'map',
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            _myProductList.isNotEmpty || _loadingUserProducts,
                        child: BarterList(
                          loading: _loadingUserProducts,
                          context: context,
                          ownList: true,
                          items: _myProductList
                              .map((product) => _buildProductItem(
                                    product: product,
                                    hideLike: true,
                                  ))
                              .toList(),
                          label: 'Your Items',
                          smallItems: true,
                          removeMargin: true,
                          onViewAllTapped: () => _rootBloc.add(MoveTab(3)),
                          removeMapBtn: true,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ..._categoryProducts.map((cat) {
                        return BarterList(
                          items: (cat['products'] as List<ProductModel>)
                              .map((product) => _buildProductItem(
                                    product: product,
                                  ))
                              .toList(),
                          label: cat['name'] as String,
                          context: context,
                          hideViewAll: true,
                          removeMapBtn: true,
                        );
                      }).toList(),
                      SizedBox(height: 10.0),
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

  Widget _buildProductItem(
      {required ProductModel product, bool hideLike = false}) {
    var thumbnail = '';

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url != null &&
        product.mediaPrimary!.url!.isNotEmpty)
      thumbnail = product.mediaPrimary!.url!;

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url_t != null &&
        product.mediaPrimary!.url_t!.isNotEmpty)
      thumbnail = product.mediaPrimary!.url_t!;

    if (product.mediaPrimary!.url!.isEmpty &&
        product.mediaPrimary!.url_t!.isEmpty &&
        product.media != null &&
        product.media!.isNotEmpty)
      thumbnail = product.media!.first.url_t != null
          ? product.media!.first.url_t!
          : product.media!.first.url!;

    return BarterListItem(
      height: hideLike ? SizeConfig.screenHeight * 0.165 : null,
      width: hideLike ? SizeConfig.screenWidth * 0.27 : null,
      fontSize: hideLike ? SizeConfig.textScaleFactor * 9 : null,
      hideLikeBtn: hideLike,
      itemName: product.productname ?? '',
      datePosted: product.updated_time ?? null,
      itemPrice:
          product.price != null ? product.price!.toStringAsFixed(2) : '0',
      imageUrl: thumbnail,
      onTapped: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productId: product.productid ?? '',
              ownItem: true,
            ),
          ),
        );

        _homeBloc.add(LoadUserList());
      },
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
