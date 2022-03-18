import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
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

  List<ProductReviewModel> _ratings = [];

  final _pagingController =
      PagingController<int, ProductReviewModel>(firstPageKey: 0);

  ProductReviewModel? lastProduct;

  int currentPage = 0;

  @override
  void initState() {
    // TODO: implement initState
    _profileBloc.add(GetUserRatings(widget.user.userid!));
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
            if (state is ProfileLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetUserRatingsSuccess) {
              if (state.list.isNotEmpty) {
                lastProduct = state.list.last;
                if (state.list.length == productCount) {
                  _pagingController.appendPage(state.list, currentPage + 1);
                } else {
                  _pagingController.appendLastPage(state.list);
                }
              } else {
                _pagingController.appendLastPage([]);
              }
              _pagingController.addPageRequestListener((pageKey) {
                if (lastProduct != null) {
                  _profileBloc.add(
                    GetNextRatings(
                      userId: lastProduct!.userid!,
                      startAfterVal: lastProduct!.rating!.toDouble(),
                      lastProductId: lastProduct!.productid!,
                    ),
                  );
                }
              });
            }

            if (state is GetNextRatingsSuccess) {
              if (state.list.isNotEmpty) {
                lastProduct = state.list.last;
                if (state.list.length == productCount) {
                  _pagingController.appendPage(state.list, currentPage + 1);
                } else {
                  _pagingController.appendLastPage(state.list);
                }
              } else {
                _pagingController.appendLastPage([]);
              }
            }
          },
          child: Column(
            children: [
              CustomAppBar(
                label: 'User Ratings',
              ),
              Expanded(
                child: _buildUserRatingsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildUserRatingsList() {
    return PagedListView<int, ProductReviewModel>(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 10.0,
      ),
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<ProductReviewModel>(
        itemBuilder: (context, rating, index) {
          return Container(
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
                    Text(rating.display_name != null &&
                            rating.display_name!.isNotEmpty
                        ? rating.display_name!
                        : 'Anonymous'),
                    Spacer(),
                    Text(timeago.format(rating.review_date ?? DateTime.now())),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(rating.review != null && rating.review!.isNotEmpty
                      ? '"${rating.review}"'
                      : '-'),
                ),
                Align(
                  alignment: Alignment.bottomRight,
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
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
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
          );
        },
      ),
    );
  }
}
