import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
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
                        items: _recommendedList.map((product) {
                          return StreamBuilder<List<UserLikesRecord?>>(
                              stream: queryUserLikesRecord(
                                queryBuilder: (userLikesRecord) =>
                                    userLikesRecord
                                        .where('userid', isEqualTo: _user!.uid)
                                        .where('productid',
                                            isEqualTo: product.productid),
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
                                  likeLeftMargin:
                                      SizeConfig.safeBlockHorizontal * 3,
                                  liked: liked,
                                  itemName: product.productname ?? '',
                                  itemPrice: product.price != null
                                      ? product.price!.toStringAsFixed(2)
                                      : '0',
                                  imageUrl: product.mediaPrimary != null &&
                                          product.mediaPrimary!.url_t != null &&
                                          product
                                              .mediaPrimary!.url_t!.isNotEmpty
                                      ? product.mediaPrimary!.url_t ?? ''
                                      : product.mediaPrimary!.url ?? '',
                                  datePosted: product.updated_time ?? null,
                                  onTapped: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsScreen(
                                          productId: product.productid ?? '',
                                          ownItem: false,
                                        ),
                                      ),
                                    );

                                    _homeBloc.add(LoadRecommendedList());
                                  },
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
                                    } else {
                                      _productBloc.add(AddLike(product));
                                    }
                                  },
                                );
                              });
                        }).toList(),
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
                        items: _trendingList.map((product) {
                          return StreamBuilder<List<UserLikesRecord?>>(
                              stream: queryUserLikesRecord(
                                queryBuilder: (userLikesRecord) =>
                                    userLikesRecord
                                        .where('userid', isEqualTo: _user!.uid)
                                        .where('productid',
                                            isEqualTo: product.productid),
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
                                  likeLeftMargin:
                                      SizeConfig.safeBlockHorizontal * 3,
                                  liked: liked,
                                  itemName: product.productname ?? '',
                                  itemPrice: product.price != null
                                      ? product.price!.toStringAsFixed(2)
                                      : '0',
                                  imageUrl: product.mediaPrimary != null &&
                                          product.mediaPrimary!.url_t != null &&
                                          product
                                              .mediaPrimary!.url_t!.isNotEmpty
                                      ? product.mediaPrimary!.url_t ?? ''
                                      : product.mediaPrimary!.url ?? '',
                                  datePosted: product.updated_time ?? null,
                                  onTapped: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsScreen(
                                          productId: product.productid ?? '',
                                          ownItem: false,
                                        ),
                                      ),
                                    );

                                    _homeBloc.add(LoadTrendingList());
                                  },
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
                                    } else {
                                      _productBloc.add(AddLike(product));
                                    }
                                  },
                                );
                              });
                        }).toList(),
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
                          items: _myProductList.map((product) {
                            return BarterListItem(
                              height: SizeConfig.screenHeight * 0.165,
                              width: SizeConfig.screenWidth * 0.27,
                              fontSize: SizeConfig.textScaleFactor * 9,
                              hideLikeBtn: true,
                              itemName: product.productname ?? '',
                              datePosted: product.updated_time ?? null,
                              itemPrice: product.price != null
                                  ? product.price!.toStringAsFixed(2)
                                  : '0',
                              imageUrl: product.mediaPrimary != null &&
                                      product.mediaPrimary!.url_t != null &&
                                      product.mediaPrimary!.url_t!.isNotEmpty
                                  ? product.mediaPrimary!.url_t ?? ''
                                  : product.mediaPrimary!.url ?? '',
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
                          }).toList(),
                          label: 'Your Items',
                          smallItems: true,
                          removeMargin: true,
                          onViewAllTapped: () => _rootBloc.add(MoveTab(3)),
                          removeMapBtn: true,
                        ),
                      ),
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
