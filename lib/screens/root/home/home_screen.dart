import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/product/product_list_screen.dart';
import 'package:tapkat/screens/root/bloc/root_bloc.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_list_screen.dart';
import 'package:tapkat/screens/store/store_screen.dart';
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
  List<StoreModel> _topStoreList = [];

  List<String> _userInterests = [];

  List<Map<String, dynamic>> _categoryProducts = [];

  final _keywordTextController = TextEditingController();

  bool _loadingRecoList = false;
  bool _loadingTrendingList = false;
  bool _loadingUserProducts = false;
  bool _loadingTopStores = false;

  User? _user;
  UserModel? _userModel;
  final _refreshController = RefreshController();

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
            bloc: _homeBloc,
            listener: (context, state) {
              if (state is LoadProductsInCategoriesSuccess) {
                _refreshController.refreshCompleted();
                setState(() {
                  _categoryProducts = state.list;
                  if (_userInterests.isNotEmpty) {
                    _userInterests.forEach((ui) {
                      final catIndex = _categoryProducts
                          .indexWhere((cp) => cp['code'] == ui);
                      if (catIndex > 0) {
                        final cat = _categoryProducts[catIndex];
                        _categoryProducts.removeAt(catIndex);
                        _categoryProducts.insert(0, cat);
                      }
                    });
                  }
                });
              }

              if (state is LoadedRecommendedList) {
                setState(() {
                  _recommendedList = state.recommended;
                  _loadingRecoList = false;
                });
              }

              if (state is LoadedTrendingList) {
                setState(() {
                  _trendingList = state.trending;
                  _loadingTrendingList = false;
                });
              }

              if (state is LoadedUserList) {
                setState(() {
                  _loadingUserProducts = false;
                  _myProductList = state.yourItems;
                });
              }

              if (state is LoadTopStoresSuccess) {
                setState(() {
                  _loadingTopStores = false;
                  _topStoreList = state.topStoreItems;
                });
              }

              if (state is LoadingTopStoreList) {
                setState(() {
                  _loadingTopStores = true;
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
                  _userModel = state.userModel;
                  print('-=-=-=-= $_userModel');
                });

                if (_userModel != null &&
                    _userModel!.interests != null &&
                    _userModel!.interests!.isNotEmpty) {
                  _userInterests = _userModel!.interests!;
                }

                _homeBloc.add(InitializeHomeScreen());
              }
            },
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
              child: SmartRefresher(
                onRefresh: () => _homeBloc.add(InitializeHomeScreen()),
                controller: _refreshController,
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
                    child: Container(
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
                          BarterList(
                            loading: _loadingTopStores,
                            context: context,
                            items: _topStoreList
                                .map((store) => InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoreScreen(
                                            userId: store.userid!,
                                            userName: store.display_name!,
                                          ),
                                        ),
                                      ),
                                      child: StoreListItem(store),
                                    ))
                                .toList(),
                            label: 'Top Stores',
                            onViewAllTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreListScreen(),
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
                            visible: _myProductList.isNotEmpty ||
                                _loadingUserProducts,
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
                            print(cat['code']);
                            return BarterList(
                              items: (cat['products'] as List<ProductModel>)
                                  .map((product) => _buildProductItem(
                                        product: product,
                                      ))
                                  .toList(),
                              label: cat['name'] as String,
                              context: context,
                              onViewAllTapped: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultScreen(
                                      userid: _user!.uid,
                                      keyword: '',
                                      category: cat['code'],
                                    ),
                                  ),
                                );
                              },
                              onMapBtnTapped: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultScreen(
                                      userid: _user!.uid,
                                      keyword: '',
                                      category: cat['code'],
                                      mapFirst: true,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                          SizedBox(height: 10.0),
                        ],
                      ),
                    ),
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
      {required ProductModel product,
      bool hideLike = false,
      UserLikesRecord? record}) {
    var thumbnail = '';

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url != null &&
        product.mediaPrimary!.url!.isNotEmpty)
      thumbnail = product.mediaPrimary!.url!;

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url_t != null &&
        product.mediaPrimary!.url_t!.isNotEmpty)
      thumbnail = product.mediaPrimary!.url_t!;

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url!.isEmpty &&
        product.mediaPrimary!.url_t!.isEmpty &&
        product.media != null &&
        product.media!.isNotEmpty)
      thumbnail = product.media!.first.url_t != null
          ? product.media!.first.url_t!
          : product.media!.first.url!;

    if (hideLike) {
      return BarterListItem(
        height: SizeConfig.screenHeight * 0.165,
        width: SizeConfig.screenWidth * 0.27,
        fontSize: SizeConfig.textScaleFactor * 9,
        hideLikeBtn: true,
        itemName: product.productname ?? '',
        datePosted: product.updated_time ?? null,
        itemPrice:
            product.price != null ? product.price!.toStringAsFixed(2) : '0',
        imageUrl: thumbnail,
        onTapped: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                productId: product.productid ?? '',
                ownItem: true,
              ),
            ),
          );
        },
      );
    }

    return StreamBuilder<List<UserLikesRecord?>>(
      stream: queryUserLikesRecord(
        queryBuilder: (userLikesRecord) => userLikesRecord
            .where('userid', isEqualTo: _user!.uid)
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

        return StreamBuilder<List<UserLikesRecord?>>(
          stream: queryUserLikesRecord(
            queryBuilder: (userLikesRecord) => userLikesRecord
                .where('userid', isEqualTo: _user!.uid)
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
              likeLeftMargin: SizeConfig.safeBlockHorizontal * 3,
              liked: liked,
              itemName: product.productname ?? '',
              itemPrice: product.price != null
                  ? product.price!.toStringAsFixed(2)
                  : '0',
              imageUrl: thumbnail,
              datePosted: product.updated_time ?? null,
              onTapped: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      productId: product.productid ?? '',
                      ownItem: false,
                    ),
                  ),
                );
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
          },
        );
      },
    );
  }

  _onSearchSubmitted(String? val) {
    _keywordTextController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          userid: _user!.uid,
          keyword: val == null || val.isEmpty
              ? ''
              : _keywordTextController.text.trim(),
        ),
      ),
    );
  }
}
