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
  late AuthBloc _authBloc;
  List<ProductModel> _recommendedList = [];
  List<ProductModel> _trendingList = [];
  List<ProductModel> _myProductList = [];
  List<ProductModel> _userFavourites = [];

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
                                  liked: liked,
                                  itemName: product.productname ?? '',
                                  itemPrice: product.price != null
                                      ? product.price!.toStringAsFixed(2)
                                      : '0',
                                  imageUrl: product.mediaPrimary != null
                                      ? product.mediaPrimary!.url!
                                      : '',
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

                                    _homeBloc.add(InitializeHomeScreen());
                                  },
                                  onLikeTapped: () {
                                    if (record != null) {
                                      final newData = createUserLikesRecordData(
                                        liked: !record.liked!,
                                      );

                                      if (record.liked!) {
                                        _onLikeTapped(product);
                                      }

                                      record.reference!.update(newData);
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
                      ),
                      BarterList(
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
                                  liked: liked,
                                  itemName: product.productname ?? '',
                                  itemPrice: product.price != null
                                      ? product.price!.toStringAsFixed(2)
                                      : '0',
                                  imageUrl: product.mediaPrimary != null
                                      ? product.mediaPrimary!.url!
                                      : '',
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

                                    _homeBloc.add(InitializeHomeScreen());
                                  },
                                  onLikeTapped: () {
                                    if (record != null) {
                                      final newData = createUserLikesRecordData(
                                        liked: !record.liked!,
                                      );

                                      if (record.liked!) {
                                        _onLikeTapped(product);
                                      }

                                      record.reference!.update(newData);
                                    }
                                  },
                                );
                              });
                        }).toList(),
                        label: 'People are Looking For',
                        onViewAllTapped: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              listType: 'demand',
                              showAdd: false,
                            ),
                          ),
                        ),
                      ),
                      BarterList(
                        context: context,
                        ownList: true,
                        items: _myProductList.map((product) {
                          return BarterListItem(
                            hideLikeBtn: true,
                            itemName: product.productname ?? '',
                            itemPrice: product.price != null
                                ? product.price!.toStringAsFixed(2)
                                : '0',
                            imageUrl: product.mediaPrimary != null
                                ? product.mediaPrimary!.url!
                                : '',
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

                              _homeBloc.add(InitializeHomeScreen());
                            },
                          );
                        }).toList(),
                        label: 'Your Items',
                        smallItems: true,
                        removeMargin: true,
                        onViewAllTapped: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductListScreen(
                                listType: 'user',
                                showAdd: true,
                                userId: _user!.uid,
                                ownListing: true,
                              ),
                            ),
                          );

                          _homeBloc.add(InitializeHomeScreen());
                        },
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

  _onLikeTapped(ProductModel product) {
    _productBloc.add(
      AddLike(product),
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
