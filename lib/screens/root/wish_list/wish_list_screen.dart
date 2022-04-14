import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/address.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/wish_list/bloc/wish_list_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:toggle_switch/toggle_switch.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({Key? key}) : super(key: key);

  @override
  _WishListScreenState createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  List<ProductModel> _list = [];
  User? _user;
  final _wishListBloc = WishListBloc();
  final _storeBloc = StoreBloc();
  final _productBloc = ProductBloc();
  final _keywordTextController = TextEditingController();
  final _refreshController = RefreshController();
  bool _loading = true;
  String _selectedView = 'products';

  List<LikedProductModel> _products = [];
  LikedProductModel? _lastProduct;
  List<LikedStoreModel> _stores = [];
  LikedStoreModel? _lastStore;

  final _productPagingController =
      PagingController<int, LikedProductModel>(firstPageKey: 0);

  final _storePagingController =
      PagingController<int, LikedStoreModel>(firstPageKey: 0);

  int currentPage = 0;

  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  @override
  void initState() {
    _wishListBloc.add(InitializeWishListScreen());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        barrierEnabled: false,
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _wishListBloc,
              listener: (context, state) {
                // print('current state: $state');
                // if (state is WishListLoading) {
                //   ProgressHUD.of(context)!.show();
                //   setState(() {
                //     _loading = true;
                //   });
                // } else {
                //   ProgressHUD.of(context)!.dismiss();
                //   setState(() {
                //     _loading = false;
                //   });
                // }

                if (state is AddLikeSuccess) {
                  _wishListBloc.add(InitializeWishListScreen());
                }

                if (state is WishListInitialized) {
                  _refreshController.refreshCompleted();
                  _productPagingController.refresh();
                  _storePagingController.refresh();
                  setState(() {
                    _user = state.user;
                  });

                  if (state.productList.isNotEmpty) {
                    _lastProduct = state.productList.last;
                    if (state.productList.length == productCount) {
                      _productPagingController.appendPage(
                          state.productList, currentPage + 1);
                    } else {
                      _productPagingController
                          .appendLastPage(state.productList);
                    }
                  } else {
                    _productPagingController.appendLastPage([]);
                  }

                  _productPagingController.addPageRequestListener((pageKey) {
                    if (_lastProduct != null) {
                      _wishListBloc.add(
                        GetNextLikedItems(
                          lastProductId: _lastProduct!.productid!,
                          lastProductDate: _lastProduct!.like_date!,
                        ),
                      );
                    }
                  });

                  if (state.storeList.isNotEmpty) {
                    _lastStore = state.storeList.last;
                    if (state.storeList.length == productCount) {
                      _storePagingController.appendPage(
                          state.storeList, currentPage + 1);
                    } else {
                      _storePagingController.appendLastPage(state.storeList);
                    }
                  } else {
                    _storePagingController.appendLastPage([]);
                  }

                  _storePagingController.addPageRequestListener((pageKey) {
                    if (_lastStore != null) {
                      _wishListBloc.add(
                        GetNextFollowedStores(
                          lastStoreId: _lastStore!.userid!,
                          lastStoreDate: _lastStore!.like_date!,
                        ),
                      );
                    }
                  });
                }

                if (state is WishListError) {
                  print('wish list error: ${state.message}');
                }
              },
            ),
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) {
                print('current wish list state: $state');
                if (state is UnlikeSuccess) {
                  _wishListBloc.add(InitializeWishListScreen());
                }
              },
            ),
            BlocListener(
              bloc: _storeBloc,
              listener: (context, state) {
                if (state is EditUserLikeSuccess) {
                  _wishListBloc.add(InitializeWishListScreen());
                }
              },
              child: Container(),
            )
          ],
          child: Container(
            color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Your Wish List',
                  hideBack: true,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      CustomSearchBar(
                        controller: _keywordTextController,
                        backgroundColor: Color(0xFF005F73).withOpacity(0.3),
                        onSubmitted: (val) => _onSearchSubmitted(val),
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  activeBgColor: [kBackgroundColor],
                  initialLabelIndex: _selectedView == 'products' ? 0 : 1,
                  minWidth: double.infinity,
                  minHeight: 25.0,
                  borderColor: [Color(0xFFEBFBFF)],
                  totalSwitches: 2,
                  customTextStyles: [
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textScaleFactor * 13,
                      color: Colors.white,
                    ),
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textScaleFactor * 13,
                      color: Colors.white,
                    ),
                  ],
                  labels: [
                    'Liked Items',
                    'Followed Stores',
                  ],
                  onToggle: (index) {
                    setState(() {
                      _selectedView = index == 0 ? 'products' : 'stores';
                    });
                  },
                ),
                Expanded(
                  child: SmartRefresher(
                    controller: _refreshController,
                    onRefresh: () =>
                        _wishListBloc.add(InitializeWishListScreen()),
                    child: _selectedView == 'products'
                        ? _buildLikedItems()
                        : _buildFollowedStores(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowedStores() {
    return PagedGridView<int, LikedStoreModel>(
      pagingController: _storePagingController,
      showNewPageProgressIndicatorAsGridChild: false,
      showNewPageErrorIndicatorAsGridChild: false,
      showNoMoreItemsIndicatorAsGridChild: false,
      padding: EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 16.0,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 16.0,
        crossAxisCount: 3,
      ),
      builderDelegate: PagedChildBuilderDelegate<LikedStoreModel>(
        itemBuilder: (context, store, index) {
          return FittedBox(
            child: StoreListItem(
              StoreModel(
                display_name: store.username,
                userid: store.userid,
                photo_url: store.user_image_url,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreScreen(
                    userId: store.userid!,
                    userName: store.username!,
                  ),
                ),
              ),
              removeLike: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikedItems() {
    return PagedGridView<int, LikedProductModel>(
      pagingController: _productPagingController,
      showNewPageProgressIndicatorAsGridChild: false,
      showNewPageErrorIndicatorAsGridChild: false,
      showNoMoreItemsIndicatorAsGridChild: false,
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 10.0,
      ),
      builderDelegate: PagedChildBuilderDelegate<LikedProductModel>(
        itemBuilder: (context, product, index) {
          return FittedBox(
            child: BarterListItem(
              likeLeftMargin: SizeConfig.screenWidth * 0.09,
              product: ProductModel(
                productid: product.productid,
                productname: product.productname,
                price: product.price,
                mediaPrimary: MediaPrimaryModel(
                  type: 'image',
                  url: product.image_url,
                  url_t: product.image_url,
                ),
              ),
              onTapped: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(
                    productId: product.productid ?? '',
                    ownItem: false,
                  ),
                ),
              ),
              onLikeTapped: (val) {
                final _prod = ProductModel(
                  productid: product.productid,
                  productname: product.productname,
                  price: product.price,
                  address: AddressModel(
                    location: product.location,
                  ),
                  mediaPrimary: MediaPrimaryModel(
                    type: 'image',
                    url: product.image_url,
                    url_t: product.image_url,
                  ),
                );
                if (val.isNegative) {
                  print('liking');
                  _productBloc.add(AddLike(_prod));
                } else {
                  print('unliking');
                  _productBloc.add(Unlike(_prod));
                }
              },
            ),
          );
        },
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
          userid: _user!.uid,
          keyword: val,
        ),
      ),
    );
  }
}
