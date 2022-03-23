import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserRatingsScreen extends StatefulWidget {
  final UserModel user;
  const UserRatingsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UserRatingsScreen> createState() => _UserRatingsScreenState();
}

class _UserRatingsScreenState extends State<UserRatingsScreen> {
  final _profileBloc = ProfileBloc();

  List<ProductReviewModel> _productRatings = [];
  List<UserReviewModel> _userReviews = [];

  final _userPagingController =
      PagingController<int, UserReviewModel>(firstPageKey: 0);

  final _productPagingController =
      PagingController<int, ProductReviewModel>(firstPageKey: 0);

  ProductReviewModel? lastProductReview;
  UserReviewModel? lastUserReview;

  int currentPage = 0;

  String _selectedView = 'products';

  @override
  void initState() {
    // TODO: implement initState
    _profileBloc.add(InitializeUserRatingsScreen(widget.user.userid!));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        child: BlocListener(
          bloc: _profileBloc,
          listener: (context, state) {
            print('current ratings state: $state');
            if (state is ProfileLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetUserRatingsSuccess) {
              if (state.list.isNotEmpty) {
                lastUserReview = state.list.last;
                if (state.list.length == productCount) {
                  _userPagingController.appendPage(state.list, currentPage + 1);
                } else {
                  _userPagingController.appendLastPage(state.list);
                }
              } else {
                _userPagingController.appendLastPage([]);
              }
              _userPagingController.addPageRequestListener((pageKey) {
                if (lastUserReview != null) {
                  _profileBloc.add(
                    GetNextUserRatings(
                      userId: lastUserReview!.userid!,
                      startAfterVal: lastUserReview!.review_date!,
                      lastUserId: lastUserReview!.userid!,
                    ),
                  );
                }
              });
            }

            if (state is GetNextUserRatingsSuccess) {
              if (state.list.isNotEmpty) {
                lastUserReview = state.list.last;
                if (state.list.length == productCount) {
                  _userPagingController.appendPage(state.list, currentPage + 1);
                } else {
                  _userPagingController.appendLastPage(state.list);
                }
              } else {
                _userPagingController.appendLastPage([]);
              }
            }

            if (state is GetProductRatingsSuccess) {
              if (state.list.isNotEmpty) {
                lastProductReview = state.list.last;
                if (state.list.length == productCount) {
                  _productPagingController.appendPage(
                      state.list, currentPage + 1);
                } else {
                  _productPagingController.appendLastPage(state.list);
                }
              } else {
                _productPagingController.appendLastPage([]);
              }

              _productPagingController.addPageRequestListener((pageKey) {
                if (lastProductReview != null) {
                  _profileBloc.add(
                    GetNextProductRatings(
                      userId: lastProductReview!.userid!,
                      startAfterVal:
                          lastProductReview!.review_date!.toIso8601String(),
                      lastProductId: lastProductReview!.productid!,
                    ),
                  );
                }
              });
            }

            if (state is GetNextProductRatingsSuccess) {
              if (state.list.isNotEmpty) {
                lastProductReview = state.list.last;
                if (state.list.length == productCount) {
                  _productPagingController.appendPage(
                      state.list, currentPage + 1);
                } else {
                  _productPagingController.appendLastPage(state.list);
                }
              } else {
                _productPagingController.appendLastPage([]);
              }
            }
          },
          child: Column(
            children: [
              CustomAppBar(
                label: 'Reviewed Products & Users',
              ),
              Container(
                margin: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                decoration: BoxDecoration(
                  // color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _onSwitchTab,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: _selectedView == 'products'
                                ? kBackgroundColor
                                : kBackgroundColor.withOpacity(0.4),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.0),
                              bottomLeft: Radius.circular(10.0),
                            ),
                          ),
                          child: Center(
                              child: Text(
                            'Products',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: SizeConfig.textScaleFactor * 16,
                            ),
                          )),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _onSwitchTab,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: _selectedView != 'products'
                                ? kBackgroundColor
                                : kBackgroundColor.withOpacity(0.4),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10.0),
                              bottomRight: Radius.circular(10.0),
                            ),
                          ),
                          child: Center(
                              child: Text(
                            'Users',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: SizeConfig.textScaleFactor * 16,
                            ),
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedView == 'products'
                    ? _buildProductRatingsList()
                    : _buildUserRatingsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onSwitchTab() {
    setState(() {
      _selectedView = _selectedView == 'products' ? 'users' : 'products';
    });

    // if (_selectedView == 'products') {
    //   // _productPagingController.refresh();
    //   _profileBloc.add(GetProductRatings(widget.user.userid!));
    // } else {
    //   _userPagingController.refresh();
    //   _profileBloc.add(GetUserRatings(widget.user.userid!));
    // }
  }

  Widget _buildProductRatingsList() {
    print('PRODUCT RATINGS');
    return PagedListView<int, ProductReviewModel>(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 10.0,
      ),
      pagingController: _productPagingController,
      builderDelegate: PagedChildBuilderDelegate<ProductReviewModel>(
        itemBuilder: (context, rating, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 10.0),
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(rating.productname ?? ''),
                    Spacer(),
                    Text(timeago.format(rating.review_date ?? DateTime.now())),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Container(
                      width: SizeConfig.screenWidth * .2,
                      height: SizeConfig.screenWidth * .2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: DecorationImage(
                          image: rating.image_url_t != null
                              ? NetworkImage(rating.image_url_t!)
                              : AssetImage(
                                      'assets/images/image_placeholder.jpg')
                                  as ImageProvider<Object>,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              rating.review != null && rating.review!.isNotEmpty
                                  ? '"${rating.review}"'
                                  : '-',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: RatingBar.builder(
                              ignoreGestures: true,
                              initialRating: rating.rating != null
                                  ? rating.rating!.roundToDouble()
                                  : 0,
                              minRating: 0,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 20,
                              tapOnlyMode: true,
                              itemPadding:
                                  EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                //
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserRatingsList() {
    return PagedListView<int, UserReviewModel>(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 10.0,
      ),
      pagingController: _userPagingController,
      builderDelegate: PagedChildBuilderDelegate<UserReviewModel>(
        itemBuilder: (context, rating, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 10.0),
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(rating.username ?? ''),
                    Spacer(),
                    Text(timeago.format(DateTime.parse(rating.review_date!))),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Container(
                      width: SizeConfig.screenWidth * .2,
                      height: SizeConfig.screenWidth * .2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: DecorationImage(
                          image: rating.user_image_url != null &&
                                  rating.user_image_url!.isNotEmpty
                              ? NetworkImage(rating.user_image_url!)
                              : AssetImage(
                                      'assets/images/image_placeholder.jpg')
                                  as ImageProvider<Object>,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              rating.review != null && rating.review!.isNotEmpty
                                  ? '"${rating.review}"'
                                  : '-',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: RatingBar.builder(
                              ignoreGestures: true,
                              initialRating: rating.rating != null
                                  ? rating.rating!.roundToDouble()
                                  : 0,
                              minRating: 0,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 20,
                              tapOnlyMode: true,
                              itemPadding:
                                  EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                //
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
