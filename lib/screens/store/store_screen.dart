import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
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

  bool _isLoading = false;

  ProductModel? lastProduct;

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  @override
  void initState() {
    _storeBloc.add(InitializeStoreScreen(widget.userId));
    storeOwnerName = widget.userId;
    storeOwnerName = storeOwnerName.length > 10
        ? storeOwnerName.substring(0, 7) + '...'
        : storeOwnerName;
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
                                        text: _storeOwner!.userid ?? ''),
                                  ),
                                  _buildInfoItem(
                                    label: 'Email',
                                    controller: TextEditingController(
                                        text: _storeOwner!.email ?? ''),
                                  ),
                                  _buildInfoItem(
                                    label: 'Phone number',
                                    controller: TextEditingController(
                                        text: _storeOwner!.mobilenum ?? ''),
                                  ),
                                  _buildInfoItem(
                                    label: 'Location',
                                    controller: TextEditingController(
                                        text:
                                            _storeOwner!.address ?? 'Unknown'),
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
              CustomSearchBar(
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                controller: TextEditingController(),
                backgroundColor: Color(0xFF005F73).withOpacity(0.3),
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
                          if (state.list.isNotEmpty) {
                            lastProduct = state.list.last;
                            _pagingController.appendPage(
                                state.list, currentPage + 1);
                            print(
                                'lastrProduct name: ${lastProduct!.productname}');
                            _pagingController.addPageRequestListener((pageKey) {
                              if (lastProduct != null) {
                                _productBloc.add(
                                  GetNextProducts(
                                    listType: 'user',
                                    lastProductId: lastProduct!.productid!,
                                    startAfterVal: lastProduct!.toString(),
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

                          print('HEYYYY');
                          if (state.list.isNotEmpty) {
                            lastProduct = state.list.last;
                            _pagingController.appendPage(
                                state.list, currentPage + 1);
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
                          setState(() {
                            _isLoading = true;
                          });
                        } else {
                          setState(() {
                            _isLoading = false;
                          });
                        }

                        if (state is InitializedStoreScreen) {
                          print(state.user.toJson());
                          setState(() {
                            _storeOwner = state.user;
                            storeOwnerName = _storeOwner!.userid!;
                          });
                          _productBloc.add(
                              GetFirstProducts('user', userId: widget.userId));
                        }
                      },
                    ),
                  ],
                  child: Container(child: _buildGridView()
                      // GridView.count(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 10.0,
                      //       vertical: 10.0,
                      //     ),
                      //     mainAxisSpacing: 16,
                      //     crossAxisCount: 2,
                      //     children: _list
                      //         .map(
                      //           (product) => Center(
                      //             child: BarterListItem(
                      //               height: SizeConfig.screenHeight * 0.23,
                      //               width: SizeConfig.screenWidth * 0.40,
                      //               hideLikeBtn: true,
                      //               itemName: product.productname ?? '',
                      //               itemPrice: product.price != null
                      //                   ? product.price!.toStringAsFixed(2)
                      //                   : '0',
                      //               imageUrl: product.mediaPrimary != null &&
                      //                       product.mediaPrimary!.url !=
                      //                           null &&
                      //                       product
                      //                           .mediaPrimary!.url!.isNotEmpty
                      //                   ? product.mediaPrimary!.url!
                      //                   : '',
                      //               onTapped: () => Navigator.push(
                      //                 context,
                      //                 MaterialPageRoute(
                      //                   builder: (context) =>
                      //                       ProductDetailsScreen(
                      //                     productId: product.productid ?? '',
                      //                   ),
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         )
                      //         .toList(),
                      //   )
                      // : Container(
                      //     padding: EdgeInsets.symmetric(horizontal: 30.0),
                      //     child: Center(
                      //       child: Column(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         children: [
                      //           Text(
                      //             'No products found',
                      //             style: Style.subtitle2
                      //                 .copyWith(color: Colors.grey),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
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
                              color: _list.isEmpty ? Colors.grey : Colors.white,
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

                  return BarterListItem(
                    height: SizeConfig.screenHeight * 0.23,
                    width: SizeConfig.screenWidth * 0.40,
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

  void _onNextTapped() {
    print('next tapped, current page $currentPage');
    if (_list.isEmpty) return;

    _productBloc.add(
      GetNextProducts(
        listType: 'user',
        lastProductId: _list.last.productid!,
        startAfterVal: _list.last.price!.toString(),
        userId: widget.userId,
      ),
    );

    setState(() {
      currentPage += 1;
    });
  }

  void _onPrevTapped() {
    if (currentPage < 1) return;

    if (currentPage == 1)
      _productBloc.add(GetFirstProducts('user', userId: widget.userId));

    if (currentPage > 1) {
      _productBloc.add(GetNextProducts(
          listType: 'user',
          lastProductId: indicators[currentPage - 2].productid!,
          startAfterVal: indicators[currentPage - 2].price!.toString()));
    }

    setState(() {
      currentPage -= 1;
    });
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
