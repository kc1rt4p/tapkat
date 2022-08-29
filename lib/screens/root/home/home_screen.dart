import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/top_store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/product/product_list_screen.dart';
import 'package:tapkat/screens/root/bloc/root_bloc.dart';
import 'package:tapkat/screens/root/home/bloc/home_bloc.dart';
import 'package:tapkat/screens/search/bloc/search_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_list_screen.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/utilities.dart';
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
  late RootBloc _rootBloc;
  final _authBloc = AuthBloc();
  final _userRepo = UserRepository();
  final _searchBloc = SearchBloc();
  final _panelController = PanelController();
  List<ProductModel> _recommendedList = [];
  List<ProductModel> _freeList = [];
  List<ProductModel> _trendingList = [];
  List<ProductModel> _myProductList = [];
  List<TopStoreModel> _topStoreList = [];
  Map<String, dynamic>? _selectedCategory;
  List<ProductModel> _selectedCategoryProducts = [];

  final _catScrollController = AutoScrollController();

  List<String> _userInterests = [];

  ProductModel? _lastCategoryProduct;

  List<Map<String, dynamic>> _categoryProducts = [];

  final _keywordTextController = TextEditingController();

  bool _loadingRecoList = true;
  bool _loadingTrendingList = true;
  bool _loadingUserProducts = true;
  bool _loadingTopStores = true;
  bool _loadingFreeList = true;
  bool _showYourItems = false;

  int currentPage = 0;
  User? _user;
  UserModel? _userModel;
  final _refreshController = RefreshController();
  bool _loadingCatProducts = false;
  List<Map<String, dynamic>> _categories = [];

  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');
  final _categoryPagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

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
      child: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _searchBloc,
            listener: (context, state) {
              if (state is SearchLoading) {
                setState(() {
                  _loadingCatProducts = true;
                });
              } else {
                setState(() {
                  _loadingCatProducts = false;
                });
              }

              if (state is SearchNextProductsSuccess) {
                if (state.list.isNotEmpty) {
                  _selectedCategoryProducts.addAll(state.list);
                  _lastCategoryProduct = state.list.last;
                  if (state.list.length == productCount) {
                    _categoryPagingController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _categoryPagingController.appendLastPage(state.list);
                  }
                } else {
                  _categoryPagingController.appendLastPage([]);
                }
              }

              if (state is SearchSuccess) {
                _refreshController.refreshCompleted();
                _lastCategoryProduct = null;

                if (state.searchResults.isNotEmpty) {
                  setState(() {
                    _selectedCategoryProducts = state.searchResults;
                  });
                  if (state.searchResults.length == productCount) {
                    _categoryPagingController.appendPage(
                        state.searchResults, currentPage + 1);
                    _lastCategoryProduct = state.searchResults.last;
                  } else {
                    _categoryPagingController
                        .appendLastPage(state.searchResults);
                  }

                  _categoryPagingController.addPageRequestListener((pageKey) {
                    if (_lastCategoryProduct != null) {
                      _searchBloc.add(
                        SearchNextProducts(
                          keyword: '',
                          lastProductId: _lastCategoryProduct!.productid!,
                          startAfterVal: _lastCategoryProduct!.productname,
                          category: _selectedCategory!['code'],
                          sortBy: 'distance',
                          distance: 20,
                        ),
                      );
                    }
                  });
                } else {
                  _selectedCategoryProducts.clear();
                  _categoryPagingController.appendLastPage([]);
                }
              }
            },
          ),
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
                  _selectedCategory = _categories.first;
                  _searchBloc.add(InitializeSearch(
                    keyword: '',
                    category: [_selectedCategory!['code'] as String],
                    sortBy: 'distance',
                    distance: 20000,
                    itemCount: 10,
                  ));
                });
              }
            },
          ),
          BlocListener(
            bloc: _homeBloc,
            listener: (context, state) async {
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

              if (state is BarterDoesNotExist) {
                final product = state.product1;
                final product2 = state.product2;
                final result = await onQuickBarter(context, product, product2);
                if (result == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarterScreen(
                      product: product,
                      initialOffer: product2,
                      quickBarter: result ? true : false,
                    ),
                  ),
                );
              }

              if (state is BarterExists) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarterScreen(
                      product: state.product1,
                      initialOffer: state.product2,
                      // existing: true,
                    ),
                  ),
                );
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
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Visibility(
                          visible:
                              !_loadingTopStores && _topStoreList.isNotEmpty,
                          child: BarterList(
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
                                  return FittedBox(
                                    child: Center(
                                      child: Stack(
                                        children: [
                                          StoreListItem(
                                            store,
                                            removeLike: true,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    StoreScreen(
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
                            onMapBtnTapped: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreListScreen(
                                  initialView: 'map',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Visibility(
                          visible:
                              !_loadingRecoList && _recommendedList.isNotEmpty,
                          child: BarterList(
                            loading: _loadingRecoList,
                            context: context,
                            items: _recommendedList.map((product) {
                              return DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          _buildProductItem(product: product),
                                  onAccept: (ProductModel product2) async {
                                    if (product.userid !=
                                            application.currentUser!.uid &&
                                        product.status != 'completed' &&
                                        product2.status != 'completed') {
                                      _homeBloc.add(
                                        CheckBarter(
                                          product1: product,
                                          product2: product2,
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
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Visibility(
                          visible:
                              !_loadingTrendingList && _trendingList.isNotEmpty,
                          child: BarterList(
                            loading: _loadingTrendingList,
                            context: context,
                            items: _trendingList.map((product) {
                              return DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          _buildProductItem(product: product),
                                  onAccept: (ProductModel product2) async {
                                    if (product.userid !=
                                            application.currentUser!.uid &&
                                        product.status != 'completed' &&
                                        product2.status != 'completed') {
                                      _homeBloc.add(
                                        CheckBarter(
                                          product1: product,
                                          product2: product2,
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
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Visibility(
                          visible: !_loadingFreeList && _freeList.isNotEmpty,
                          child: BarterList(
                            loading: _loadingFreeList,
                            context: context,
                            items: _freeList.map((product) {
                              return DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          _buildProductItem(product: product),
                                  onAccept: (ProductModel product2) async {
                                    if (product.userid !=
                                            application.currentUser!.uid &&
                                        product.status != 'completed' &&
                                        product2.status != 'completed') {
                                      _homeBloc.add(
                                        CheckBarter(
                                          product1: product,
                                          product2: product2,
                                        ),
                                      );
                                      // final result = await onQuickBarter(
                                      //     context, product, product2);
                                      // if (result == false) {
                                      //   _homeBloc.add(
                                      //     CheckBarter(
                                      //       product1: product,
                                      //       product2: product2,
                                      //     ),
                                      //   );
                                      // }
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
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 10.0),
                      ),
                      SliverAppBar(
                        titleSpacing: 0,
                        backgroundColor: Color(0xFFEBFBFF),
                        elevation: 0,
                        centerTitle: true,
                        primary: false,
                        // floating: true,
                        automaticallyImplyLeading: false,
                        pinned: true,
                        stretch: true,
                        toolbarHeight: 80.0,
                        title: Column(
                          children: [
                            Container(
                              height: 50.0,
                              width: double.infinity,
                              child: ListView(
                                controller: _catScrollController,
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                children:
                                    _categories.asMap().entries.map((cat) {
                                  return AutoScrollTag(
                                    key: ValueKey(cat.key),
                                    controller: _catScrollController,
                                    index: cat.key,
                                    child: InkWell(
                                      onTap: () {
                                        final index = cat.key;
                                        _categoryPagingController.refresh();
                                        setState(() {
                                          _categories.removeAt(index);
                                          _categories.insert(0, cat.value);
                                          _selectedCategory = cat.value;
                                        });
                                        _catScrollController.scrollToIndex(0,
                                            preferPosition:
                                                AutoScrollPosition.begin);
                                        _searchBloc.add(
                                          InitializeSearch(
                                            keyword: '',
                                            category: [
                                              _selectedCategory!['code']
                                                  as String
                                            ],
                                            sortBy: 'name',
                                            distance: 20000,
                                            itemCount: 10,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 90.0,
                                        height: 50.0,
                                        margin: EdgeInsets.only(right: 8.0),
                                        decoration: BoxDecoration(
                                          color: _selectedCategory == cat.value
                                              ? kBackgroundColor
                                              : null,
                                          border: Border.all(
                                            color: kBackgroundColor,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Center(
                                          child: Text(
                                            cat.value['name'] as String,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            style: TextStyle(
                                              fontWeight:
                                                  _selectedCategory == cat.value
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                              fontSize:
                                                  SizeConfig.textScaleFactor *
                                                      11,
                                              color:
                                                  _selectedCategory == cat.value
                                                      ? Colors.white
                                                      : kBackgroundColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            _selectedCategory != null &&
                                    _selectedCategoryProducts.isNotEmpty
                                ? Container(
                                    child: TextButton(
                                      child: Text(
                                        'See All',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: kBackgroundColor,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(50, 30),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SearchResultScreen(
                                              userid: _user!.uid,
                                              keyword: '',
                                              category:
                                                  _selectedCategory!['code'],
                                              initialRadius: 20000,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 20.0),
                      ),
                      PagedSliverGrid<int, ProductModel>(
                        pagingController: _categoryPagingController,
                        showNewPageProgressIndicatorAsGridChild: false,
                        showNewPageErrorIndicatorAsGridChild: false,
                        showNoMoreItemsIndicatorAsGridChild: false,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisSpacing: 10.0,
                          crossAxisCount: SizeConfig.screenWidth > 500 ? 3 : 2,
                        ),
                        builderDelegate:
                            PagedChildBuilderDelegate<ProductModel>(
                          itemBuilder: (context, product, index) {
                            return DragTarget(
                                builder:
                                    (context, candidateData, rejectedData) =>
                                        _buildProductItem(product: product),
                                onAccept: (ProductModel product2) async {
                                  if (product.userid !=
                                          application.currentUser!.uid &&
                                      product.status != 'completed' &&
                                      product2.status != 'completed') {
                                    _homeBloc.add(
                                      CheckBarter(
                                        product1: product,
                                        product2: product2,
                                      ),
                                    );
                                    // final result = await onQuickBarter(
                                    //     context, product, product2);
                                    // if (result == false) {
                                    //   _homeBloc.add(
                                    //     CheckBarter(
                                    //       product1: product,
                                    //       product2: product2,
                                    //     ),
                                    //   );
                                    // }
                                  }
                                  print(product.toJson());
                                });
                            // return DragTarget(
                            //     builder: (context, candidateData,
                            //             rejectedData) =>
                            //         FittedBox(
                            //           child: BarterListItem(
                            //             likeLeftMargin: 25,
                            //             product: product,
                            //             onTapped: () => Navigator.push(
                            //               context,
                            //               MaterialPageRoute(
                            //                 builder: (context) =>
                            //                     ProductDetailsScreen(
                            //                   productId:
                            //                       product.productid ?? '',
                            //                 ),
                            //               ),
                            //             ),
                            //             onLikeTapped: (val) {
                            //               if (val.isNegative) {
                            //                 _productBloc.add(AddLike(product));
                            //               } else {
                            //                 _productBloc.add(Unlike(product));
                            //               }
                            //             },
                            //           ),
                            //         ),
                            //     onAccept: (ProductModel product2) async {
                            //       if (product.userid !=
                            //               application.currentUser!.uid &&
                            //           product.status != 'completed' &&
                            //           product2.status != 'completed') {
                            //         _homeBloc.add(
                            //           CheckBarter(
                            //             product1: product,
                            //             product2: product2,
                            //           ),
                            //         );
                            //       }
                            //     });
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                            height: _loadingCatProducts ||
                                    _categoryPagingController.itemList ==
                                        null ||
                                    (_categoryPagingController.itemList !=
                                            null &&
                                        _categoryPagingController
                                                .itemList!.length <
                                            10)
                                ? SizeConfig.screenHeight * 0.5
                                : 20.0),
                      ),
                    ],
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
                height: SizeConfig.screenHeight * 0.5,
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
                            height: SizeConfig.screenHeight * 0.1,
                            width: SizeConfig.screenHeight * 0.1,
                            decoration: BoxDecoration(
                              color: kBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(''),
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
      {required ProductModel product, bool hideLike = false}) {
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

  // _onProductDragged(ProductModel product) {
  //   final _barterId =
  //       application.currentUser!.uid + product.userid! + product.productid!;
  //   _homeBloc.add(CheckBarter(product));
  // }

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
