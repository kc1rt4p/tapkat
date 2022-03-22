import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

import '../../backend.dart';

class StoreScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const StoreScreen({Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _productBloc = ProductBloc();
  final _storeBloc = StoreBloc();
  List<ProductModel> _list = [];

  int currentPage = 0;

  List<ProductModel> indicators = [];

  String storeOwnerName = '';
  UserModel? _storeOwner;

  ProductModel? lastProduct;

  final _refreshController = RefreshController();

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  @override
  void initState() {
    _storeBloc.add(InitializeStoreScreen(widget.userId));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      backgroundColor: Colors.white,
      indicatorColor: kBackgroundColor,
      child: Scaffold(
        body: Container(
          child: SmartRefresher(
            controller: _refreshController,
            onRefresh: () =>
                _storeBloc.add(InitializeStoreScreen(widget.userId)),
            child: Column(
              children: [
                CustomAppBar(
                  label: '$storeOwnerName\'s Store',
                ),
                _storeOwner != null
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 10.0,
                        ),
                        child: Row(
                          children: [
                            _buildPhoto(),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildInfoItem(
                                      label: 'Store Owner',
                                      controller: TextEditingController(
                                          text: storeOwnerName),
                                    ),
                                    _buildInfoItem(
                                      label: 'Email',
                                      controller: TextEditingController(
                                          text: _storeOwner!.email ?? ''),
                                    ),
                                    _buildInfoItem(
                                      label: 'Phone number',
                                      controller: TextEditingController(
                                          text:
                                              _storeOwner!.phone_number ?? ''),
                                    ),
                                    _buildInfoItem(
                                      label: 'Location',
                                      controller: TextEditingController(
                                          text: (_storeOwner!.address != null &&
                                                  _storeOwner!.city != null &&
                                                  _storeOwner!.country != null)
                                              ? (_storeOwner!.address ?? '') +
                                                  ', ' +
                                                  (_storeOwner!.city ?? '') +
                                                  ', ' +
                                                  (_storeOwner!.country ?? '')
                                              : ''),
                                      suffix: Icon(
                                        FontAwesomeIcons.mapMarked,
                                        color: kBackgroundColor,
                                        size: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 10.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'User Reviews',
                              style: Style.subtitle2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              FontAwesomeIcons.chevronRight,
                              color: Colors.white,
                              size: 14.0,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              margin: EdgeInsets.zero,
                              controller: TextEditingController(),
                              backgroundColor: kBackgroundColor,
                              textColor: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10.0),
                          InkWell(
                            onTap: () {},
                            child: Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    offset: Offset(0, 0.5),
                                    blurRadius: 0.5,
                                    spreadRadius: 0.5,
                                    color: Color(0xFF005F73).withOpacity(0.3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.solidMap,
                                size: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
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

                          if (state is GetFirstProductsSuccess) {
                            // setState(() {
                            //   currentPage = 0;
                            //   _list = state.list;
                            //   indicators.clear();
                            //   if (_list.isNotEmpty) {
                            //     indicators.add(_list.last);
                            //   }
                            // });
                            _refreshController.refreshCompleted();
                            _pagingController.refresh();
                            if (state.list.isNotEmpty) {
                              _list.addAll(state.list);
                              lastProduct = state.list.last;
                              if (state.list.length == productCount) {
                                _pagingController.appendPage(
                                    state.list, currentPage + 1);
                              } else {
                                _pagingController.appendLastPage(state.list);
                              }
                              print(
                                  'lastrProduct name: ${lastProduct!.productname}');
                              _pagingController
                                  .addPageRequestListener((pageKey) {
                                if (lastProduct != null) {
                                  _productBloc.add(
                                    GetNextProducts(
                                      listType: 'user',
                                      lastProductId: lastProduct!.productid!,
                                      startAfterVal:
                                          lastProduct!.price.toString(),
                                      userId: widget.userId,
                                    ),
                                  );
                                }
                              });
                            }
                          }

                          if (state is GetProductsSuccess) {
                            // setState(() {
                            //   _list = state.list;

                            //   indicators.add(_list.last);
                            // });

                            // indicators.asMap().forEach((key, value) =>
                            //     print('==== page : ${value.productid}'));

                            if (state.list.isNotEmpty) {
                              lastProduct = state.list.last;
                              if (state.list.length == productCount) {
                                _pagingController.appendPage(
                                    state.list, currentPage + 1);
                              } else {
                                _pagingController.appendLastPage(state.list);
                              }
                            } else {
                              _pagingController.appendLastPage([]);
                            }
                          }
                        },
                      ),
                      BlocListener(
                        bloc: _storeBloc,
                        listener: (context, state) {
                          if (state is LoadingStore) {
                            ProgressHUD.of(context)!.show();
                          } else {
                            setState(() {
                              ProgressHUD.of(context)!.dismiss();
                            });
                          }

                          if (state is InitializedStoreScreen) {
                            print(state.user.toJson());
                            setState(() {
                              _storeOwner = state.user;
                              storeOwnerName = _storeOwner!.display_name!;
                            });
                            _productBloc.add(GetFirstProducts('user',
                                userId: widget.userId));
                          }
                        },
                      ),
                    ],
                    child: Container(child: _buildGridView()),
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

                  return BarterListItem(
                    height: SizeConfig.screenHeight * 0.22,
                    width: SizeConfig.screenWidth * 0.40,
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

  Container _buildInfoItem({
    required String label,
    required TextEditingController controller,
    Widget? suffix,
    Function()? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.0),
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Text(
            label,
            style: Style.fieldTitle.copyWith(
                color: kBackgroundColor,
                fontSize: SizeConfig.textScaleFactor * 11),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                controller.text,
                textAlign: TextAlign.right,
                style: Style.fieldText
                    .copyWith(fontSize: SizeConfig.textScaleFactor * 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stack _buildPhoto() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.0),
            image: DecorationImage(
              image: _storeOwner != null &&
                      (_storeOwner!.photo_url != null &&
                          _storeOwner!.photo_url != '')
                  ? CachedNetworkImageProvider(_storeOwner!.photo_url!)
                  : AssetImage('assets/images/profile_placeholder.png')
                      as ImageProvider<Object>,
              scale: 1.0,
              fit: BoxFit.cover,
            ),
          ),
          height: SizeConfig.screenWidth * .24,
          width: SizeConfig.screenWidth * .24,
        ),
      ],
    );
  }
}
