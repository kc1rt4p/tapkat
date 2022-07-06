import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/product/product_list_screen.dart';
import 'package:tapkat/screens/root/bloc/root_bloc.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_list_screen.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

import 'package:tapkat/utilities/application.dart' as application;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _homeBloc = HomeBloc();
  final _productBloc = ProductBloc();
  final _storeBloc = StoreBloc();
  late RootBloc _rootBloc;
  final _authBloc = AuthBloc();
  final _userRepo = UserRepository();
  final _panelController = PanelController();
  List<ProductModel> _recommendedList = [];
  List<ProductModel> _freeList = [];
  List<ProductModel> _trendingList = [];
  List<ProductModel> _myProductList = [];
  List<StoreModel> _topStoreList = [];

  List<String> _userInterests = [];

  List<Map<String, dynamic>> _categoryProducts = [];

  final _keywordTextController = TextEditingController();

  bool _loadingRecoList = true;
  bool _loadingTrendingList = true;
  bool _loadingUserProducts = true;
  bool _loadingTopStores = true;
  bool _loadingFreeList = true;
  bool _showYourItems = false;

  User? _user;
  UserModel? _userModel;
  final _refreshController = RefreshController();
  bool _loadingCatProducts = false;
  List<Map<String, dynamic>> _categories = [];

  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  @override
  void initState() {
    application.currentScreen = 'HOME SCREEN';
    _rootBloc = BlocProvider.of<RootBloc>(context);
    _productBloc.add(GetCategories());
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      indicatorColor: kBackgroundColor,
      barrierEnabled: false,
      child: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _productBloc,
            listener: (context, state) {
              if (state is ProductLoading) {
                setState(() {
                  _loadingCatProducts = true;
                });
              }

              if (state is GetCategoriesSuccess) {
                setState(() {
                  state.list.forEach((cat) {
                    _categories.add({
                      'code': cat.code,
                      'name': cat.name,
                    });
                  });
                });
              }
            },
          ),
          BlocListener(
            bloc: _homeBloc,
            listener: (context, state) {
              if (state is LoadProductsInCategoriesSuccess) {
                _refreshController.refreshCompleted();
                setState(() {
                  _categoryProducts = state.list;

                  _categoryProducts.forEach((catList) {
                    final index = _categories
                        .indexWhere((cat) => cat['code'] == catList['code']);
                    if (index > -1) {
                      _categories[index].addAll({
                        'products': catList['products'],
                      });
                    }
                  });

                  if (_userInterests.isNotEmpty) {
                    _userInterests.forEach((ui) {
                      final catIndex =
                          _categories.indexWhere((cp) => cp['code'] == ui);
                      if (catIndex > 0) {
                        final cat = _categories[catIndex];
                        _categories.removeAt(catIndex);
                        _categories.insert(0, cat);
                      }
                    });
                  }
                });

                setState(() {
                  _loadingCatProducts = false;
                });
              }

              if (state is LoadedRecommendedList) {
                setState(() {
                  _recommendedList = state.recommended;
                  _loadingRecoList = false;
                });
              }

              if (state is LoadedFreeList) {
                setState(() {
                  _freeList = state.list;
                  _loadingFreeList = false;
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

              if (state is LoadingFreeList) {
                setState(() {
                  _loadingFreeList = true;
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
              margin: EdgeInsets.only(top: SizeConfig.paddingTop),
              padding: EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: CustomSearchBar(
                controller: _keywordTextController,
                onSubmitted: (val) => _onSearchSubmitted(val),
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
                child: SmartRefresher(
                  onRefresh: () => _homeBloc.add(InitializeHomeScreen()),
                  controller: _refreshController,
                  child: SingleChildScrollView(
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BarterList(
                            loading: _loadingTopStores,
                            loadingSize: 50.0,
                            context: context,
                            items: _topStoreList.map((store) {
                              return StreamBuilder<bool>(
                                stream: _userRepo
                                    .streamUserOnlineStatus(store.userid!),
                                builder: (context, snapshot) {
                                  bool online = false;
                                  if (snapshot.hasData) {
                                    online = snapshot.data ?? false;
                                  }
                                  return Center(
                                    child: Stack(
                                      children: [
                                        StoreListItem(
                                          StoreModel(
                                            display_name: store.display_name,
                                            userid: store.userid,
                                            photo_url: store.photo_url,
                                          ),
                                          removeLike: true,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => StoreScreen(
                                                userId: store.userid!,
                                                userName: store.display_name!,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 5,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                height: 12.0,
                                                width: 12.0,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Container(
                                                height: 10.0,
                                                width: 10.0,
                                                decoration: BoxDecoration(
                                                  color: online
                                                      ? Colors.green
                                                      : Colors.grey,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                            label: 'Stores Around You',
                            onViewAllTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreListScreen(),
                              ),
                            ),
                            removeMapBtn: true,
                          ),
                          BarterList(
                            loading: _loadingRecoList,
                            context: context,
                            items: _recommendedList.map((product) {
                              return DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          _buildProductItem(product: product),
                                  onAccept: (ProductModel product2) {
                                    if (product.userid !=
                                            application.currentUser!.uid &&
                                        product.status != 'completed' &&
                                        product2.status != 'completed') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BarterScreen(
                                            product: product,
                                            initialOffer: product2,
                                          ),
                                        ),
                                      );
                                    }
                                  });
                            }).toList(),
                            label: 'Recommended For You',
                            onViewAllTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  listType: 'reco',
                                  showAdd: false,
                                  userId: application.currentUser!.uid,
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
                                  userId: application.currentUser!.uid,
                                ),
                              ),
                            ),
                          ),
                          BarterList(
                            loading: _loadingTrendingList,
                            context: context,
                            items: _trendingList.map((product) {
                              return DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          _buildProductItem(product: product),
                                  onAccept: (ProductModel product2) {
                                    if (product.userid !=
                                        application.currentUser!.uid) {
                                      print(product.toJson());
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BarterScreen(
                                            product: product,
                                            initialOffer: product2,
                                          ),
                                        ),
                                      );
                                    }
                                  });
                            }).toList(),
                            label: 'What\'s Hot',
                            onViewAllTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  listType: 'demand',
                                  showAdd: false,
                                  userId: application.currentUser!.uid,
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
                            loading: _loadingFreeList,
                            context: context,
                            items: _freeList.map((product) {
                              return DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          _buildProductItem(product: product),
                                  onAccept: (ProductModel product2) {
                                    if (product.userid !=
                                        application.currentUser!.uid) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BarterScreen(
                                            product: product,
                                            initialOffer: product2,
                                          ),
                                        ),
                                      );
                                    }
                                    print(product.toJson());
                                  });
                            }).toList(),
                            label: 'Free products',
                            onViewAllTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  listType: 'free',
                                  showAdd: false,
                                  userId: application.currentUser!.uid,
                                ),
                              ),
                            ),
                            onMapBtnTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(
                                  listType: 'free',
                                  showAdd: false,
                                  initialView: 'map',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.0),
                          ..._categories.map((cat) {
                            return BarterList(
                              loading: _loadingCatProducts,
                              items: cat['products'] != null
                                  ? (cat['products'] as List<ProductModel>)
                                      .map((product) {
                                      return DragTarget(
                                          builder: (context, candidateData,
                                                  rejectedData) =>
                                              _buildProductItem(
                                                  product: product),
                                          onAccept: (ProductModel product2) {
                                            if (product.userid !=
                                                application.currentUser!.uid) {
                                              print(product.toJson());
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BarterScreen(
                                                    product: product,
                                                    initialOffer: product2,
                                                  ),
                                                ),
                                              );
                                            }
                                          });
                                    }).toList()
                                  : [],
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
            SlidingUpPanel(
              isDraggable: true,
              controller: _panelController,
              backdropEnabled: false,
              minHeight: SizeConfig.screenHeight * 0.06,
              maxHeight: SizeConfig.screenHeight * 0.22,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        'Your Items',
                        style: Style.subtitle2.copyWith(
                          color: kBackgroundColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
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
                child: SingleChildScrollView(
                  child: BarterList(
                    onLabelTapped: () {
                      _panelController.close();
                    },
                    labelSuffix: Icon(
                      _showYourItems
                          ? Icons.arrow_drop_down
                          : Icons.arrow_drop_up,
                      color: kBackgroundColor,
                    ),
                    loading: _loadingUserProducts,
                    context: context,
                    ownList: true,
                    items: _myProductList.map(
                      (product) {
                        var thumbnail = '';

                        if (product.media != null &&
                            product.media!.isNotEmpty) {
                          for (var media in product.media!) {
                            thumbnail = media.url_t ?? '';
                            if (thumbnail.isNotEmpty) break;
                          }
                        }

                        if (thumbnail.isEmpty) {
                          if (product.mediaPrimary != null &&
                              product.mediaPrimary!.url_t != null &&
                              product.mediaPrimary!.url_t!.isNotEmpty)
                            thumbnail = product.mediaPrimary!.url_t!;
                        }
                        return LongPressDraggable(
                          data: product,
                          childWhenDragging: Container(
                            height: SizeConfig.screenHeight * 0.12,
                            width: SizeConfig.screenHeight * 0.12,
                            decoration: BoxDecoration(
                              color: kBackgroundColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                topRight: Radius.circular(20.0),
                              ),
                            ),
                          ),
                          feedback: Container(
                            height: 100.0,
                            width: 100.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: thumbnail.isNotEmpty
                                    ? CachedNetworkImageProvider(thumbnail)
                                    : AssetImage(
                                            'assets/images/image_placeholder.jpg')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                          child: BarterListItem(
                            height: SizeConfig.screenHeight * 0.07,
                            width: SizeConfig.screenHeight * 0.12,
                            hideLikeBtn: true,
                            hideDistance: true,
                            showRating: false,
                            product: product,
                            onTapped: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsScreen(
                                    productId: product.productid ?? '',
                                    ownItem: false,
                                  ),
                                ),
                              );

                              if (changed == true) {
                                _homeBloc.add(LoadUserList());
                              }
                            },
                          ),
                        );
                      },
                    ).toList(),
                    label: 'Your Items',
                    smallItems: true,
                    removeMargin: true,
                    onViewAllTapped: () => _rootBloc.add(MoveTab(3)),
                    removeMapBtn: true,
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
    if (hideLike) {
      return BarterListItem(
        product: product,
        height: SizeConfig.screenHeight * 0.17,
        width: SizeConfig.screenHeight * 0.17,
        hideLikeBtn: product.userid == application.currentUserModel!.userid,
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
        onLikeTapped: (val) {
          print('---===== $val');
          if (val.isNegative) {
            _productBloc.add(AddLike(product));
          } else {
            _productBloc.add(Unlike(product));
          }
        },
      );
    }

    return Center(
      child: BarterListItem(
        product: product,
        likeLeftMargin: SizeConfig.safeBlockHorizontal * 3,
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
        onLikeTapped: (val) {
          if (val.isNegative) {
            _productBloc.add(AddLike(product));
          } else {
            _productBloc.add(Unlike(product));
          }
        },
      ),
    );
  }

  _onSearchSubmitted(String? val) async {
    await Navigator.push(
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

    _keywordTextController.clear();
  }
}
