import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tapkat/utilities/application.dart' as application;

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
    application.currentScreen = 'User Ratings Screen';
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
              lastUserReview = null;
              _userPagingController.refresh();
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

            if (state is UpdateProductReviewSuccess ||
                state is UpdateUserReviewSuccess ||
                state is DeleteUserReviewSuccess ||
                state is DeleteProductReviewSuccess) {
              _profileBloc
                  .add(InitializeUserRatingsScreen(widget.user.userid!));
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
              lastProductReview = null;
              _productPagingController.refresh();
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
          return InkWell(
            onLongPress: () => _onLongPressProduct(rating),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  productId: rating.productid ?? '',
                  ownItem: false,
                ),
              ),
            ),
            child: Container(
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
                      Expanded(child: Text(rating.productname ?? '')),
                      SizedBox(width: 8.0),
                      Text(
                        timeago.format(rating.review_date ?? DateTime.now()),
                        style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 10),
                      ),
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
                            image: rating.image_url_t != null &&
                                    rating.image_url_t!.isNotEmpty
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(
                                rating.review != null &&
                                        rating.review!.isNotEmpty
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
                                itemSize: SizeConfig.textScaleFactor * 13,
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
            ),
          );
        },
      ),
    );
  }

  _onLongPressUser(UserReviewModel user) async {
    final operation = await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          ],
        ),
      ),
    );

    if (operation == 'delete') {
      _profileBloc.add(DeleteUserReview(user));
    }

    if (operation == 'edit') {
      _onUserReviewUpdate(user);
    }
  }

  _onLongPressProduct(ProductReviewModel review) async {
    final operation = await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          ],
        ),
      ),
    );
    print('selected op: $operation');
    if (operation == 'delete') {
      _profileBloc.add(DeleteProductReview(review));
    }
    if (operation == 'edit') {
      _onProductReviewUpdate(review);
    }
  }

  _onUserReviewUpdate(UserReviewModel review) async {
    final _reviewTextController = TextEditingController();
    num _rating = 0;
    if (review != null) {
      _reviewTextController.text = review.review ?? '';
      _rating = review.rating ?? 0;
    }

    final rating = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rate User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBackgroundColor,
                            fontSize: SizeConfig.textScaleFactor * 15.0,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: kBackgroundColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBar.builder(
                        initialRating:
                            review != null ? review.rating!.toDouble() : 0,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 20,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _rating = rating;
                          });
                        },
                      ),
                      Text(_rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 16.0)),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  CustomTextFormField(
                    label: 'Review',
                    hintText: 'Write a user review',
                    controller: _reviewTextController,
                    textColor: kBackgroundColor,
                    maxLines: 3,
                  ),
                  CustomButton(
                    bgColor: kBackgroundColor,
                    label: 'UPDATE',
                    onTap: () {
                      Navigator.pop(context, {
                        'rating': _rating,
                        'review': _reviewTextController.text.trim(),
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (rating != null) {
      _profileBloc.add(UpdateUserReview(
        UserReviewModel(
          rating: rating['rating'] as double,
          review: rating['review'] as String?,
          reviewerid: review.reviewerid,
          reviewername: review.reviewername,
          userid: review.userid,
          username: review.username,
        ),
      ));
    }
  }

  _onProductReviewUpdate(ProductReviewModel review) async {
    final updatedReview = await showDialog(
        context: context,
        builder: (context) {
          final _reviewTextController = TextEditingController(
              text: review.review != null ? review.review : '');
          num _rating = review.rating != null ? review.rating ?? 0 : 0.0;
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Dialog(
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Edit review', style: Style.subtitle2),
                        Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context, null),
                          child: Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Container(
                          width: SizeConfig.screenWidth * .1,
                          height: SizeConfig.screenWidth * .1,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            image: DecorationImage(
                              image: review.image_url_t != null
                                  ? NetworkImage(review.image_url_t!)
                                  : AssetImage(
                                          'assets/images/image_placeholder.jpg')
                                      as ImageProvider<Object>,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            review.productname ?? '',
                            style: TextStyle(
                              fontSize: SizeConfig.textScaleFactor * 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RatingBar.builder(
                          initialRating: review.rating != null
                              ? review.rating!.toDouble()
                              : 0.0,
                          minRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 20,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) =>
                              setState(() => _rating = rating),
                        ),
                        Text('${_rating.toStringAsFixed(1)}'),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    CustomTextFormField(
                      label: 'Review',
                      hintText: 'Write a user review',
                      controller: _reviewTextController,
                      textColor: kBackgroundColor,
                      maxLines: 3,
                    ),
                    CustomButton(
                      enabled: _rating > 0,
                      bgColor: kBackgroundColor,
                      label: 'UPDATE',
                      onTap: () {
                        Navigator.pop(context, {
                          'rating': _rating,
                          'review': _reviewTextController.text.trim(),
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        });

    if (updatedReview != null) {
      _profileBloc.add(UpdateProductReview(
        ProductReviewModel(
          rating: updatedReview['rating'] + 0.0,
          review: updatedReview['review'] as String?,
          display_name: review.display_name,
          productid: review.productid,
          productname: review.productname,
          image_url_t: review.image_url_t,
          userid: review.userid,
          reviewerid: review.reviewerid,
        ),
      ));
    }
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
          return InkWell(
            onLongPress: () => _onLongPressUser(rating),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreScreen(
                  userId: rating.userid!,
                  userName: rating.username!,
                ),
              ),
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
                        SizedBox(width: 5.0),
                        Expanded(
                          child: Text(
                            rating.username ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          timeago.format(DateTime.parse(rating.review_date!)),
                          style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 10,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    RatingBar.builder(
                      ignoreGestures: true,
                      initialRating: rating.rating != null
                          ? rating.rating!.roundToDouble()
                          : 0,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: SizeConfig.textScaleFactor * 13,
                      tapOnlyMode: true,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        //
                      },
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      rating.review != null && rating.review!.isNotEmpty
                          ? '"${rating.review}"'
                          : '-',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
          return InkWell(
            onLongPress: () => _onLongPressUser(rating),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreScreen(
                  userId: rating.userid!,
                  userName: rating.username!,
                ),
              ),
            ),
            child: Container(
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
                      Expanded(child: Text(rating.username ?? '')),
                      SizedBox(width: 8.0),
                      Text(timeago.format(DateTime.parse(rating.review_date!)),
                          style: TextStyle(
                              fontSize: SizeConfig.textScaleFactor * 10)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: SizeConfig.screenWidth * .17,
                        height: SizeConfig.screenWidth * .17,
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
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: RatingBar.builder(
                                ignoreGestures: true,
                                initialRating: rating.rating != null
                                    ? rating.rating!.roundToDouble()
                                    : 0,
                                minRating: 0,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: SizeConfig.textScaleFactor * 13,
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
                            Container(
                              height: 100.0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: SingleChildScrollView(
                                child: Text(
                                  rating.review != null &&
                                          rating.review!.isNotEmpty
                                      ? '"${rating.review}"'
                                      : '-',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
