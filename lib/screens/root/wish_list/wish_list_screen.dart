import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/wish_list/bloc/wish_list_bloc.dart';
import 'package:tapkat/screens/search/search_result_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({Key? key}) : super(key: key);

  @override
  _WishListScreenState createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  List<ProductModel> _list = [];
  User? _user;
  final _wishListBloc = WishListBloc();
  final _productBloc = ProductBloc();
  final _keywordTextController = TextEditingController();

  bool _loading = true;

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
                print('current state: $state');
                if (state is WishListLoading) {
                  ProgressHUD.of(context)!.show();
                  setState(() {
                    _loading = true;
                  });
                } else {
                  ProgressHUD.of(context)!.dismiss();
                  setState(() {
                    _loading = false;
                  });
                }

                if (state is WishListInitialized) {
                  setState(() {
                    _list = state.list;
                    _user = state.user;
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
          ],
          child: Container(
            color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Your Wish List',
                  hideBack: true,
                ),
                CustomSearchBar(
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  controller: _keywordTextController,
                  backgroundColor: Color(0xFF005F73).withOpacity(0.3),
                  onSubmitted: (val) => _onSearchSubmitted(val),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text('Sort by:'),
                      SizedBox(width: 5.0),
                      _buildSortOption(),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9.0),
                              color: Colors.white),
                          child: Center(
                              child: Text(
                            'Most Recent',
                            style: TextStyle(
                              fontSize: 12.0,
                            ),
                          )),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9.0),
                              color: Colors.white),
                          child: Row(
                            children: [
                              Text(
                                'Price',
                                style: TextStyle(
                                  fontSize: 12.0,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 14.0,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    child: _list.isNotEmpty
                        ? GridView.count(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 10.0),
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            mainAxisSpacing: 8.0,
                            children: _list.map((product) {
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
                              return Center(
                                child: StreamBuilder<List<UserLikesRecord?>>(
                                    stream: queryUserLikesRecord(
                                      queryBuilder: (userLikesRecord) =>
                                          userLikesRecord
                                              .where('userid',
                                                  isEqualTo: _user!.uid)
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
                                        height: SizeConfig.screenHeight * 0.23,
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
                                            builder: (context) =>
                                                ProductDetailsScreen(
                                              productId:
                                                  product.productid ?? '',
                                            ),
                                          ),
                                        ),
                                        onLikeTapped: () {
                                          if (record != null) {
                                            final newData =
                                                createUserLikesRecordData(
                                              liked: !record.liked!,
                                            );

                                            record.reference!.update(newData);

                                            if (liked) {
                                              _productBloc.add(
                                                Unlike(product),
                                              );
                                            } else {
                                              _productBloc
                                                  .add(AddLike(product));
                                            }
                                          }
                                        },
                                      );
                                    }),
                              );
                            }).toList(),
                          )
                        : Visibility(
                            visible: !_loading,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 30.0),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'No products found',
                                      style: Style.subtitle2
                                          .copyWith(color: Colors.grey),
                                    ),
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

  Expanded _buildSortOption() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.0),
          color: Colors.white,
        ),
        child: Center(
            child: Text(
          'Relevance',
          style: TextStyle(
            fontSize: 12.0,
          ),
        )),
      ),
    );
  }
}
