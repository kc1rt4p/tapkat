import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:tapkat/utilities/application.dart' as application;

class UserReviewListScreen extends StatefulWidget {
  final String userId;
  const UserReviewListScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<UserReviewListScreen> createState() => _UserReviewListScreenState();
}

class _UserReviewListScreenState extends State<UserReviewListScreen> {
  final _userPagingController =
      PagingController<int, UserReviewModel>(firstPageKey: 0);
  final _profileBloc = ProfileBloc();

  UserReviewModel? _lastUserReview;

  int currentPage = 0;

  @override
  void initState() {
    application.currentScreen = 'User Review List Screen';
    _profileBloc.add(GetRatingsForUser(widget.userId));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener(
        bloc: _profileBloc,
        listener: (context, state) {
          if (state is GetUserRatingsSuccess) {
            if (state.list.isNotEmpty) {
              _lastUserReview = state.list.last;
              if (state.list.length == productCount) {
                _userPagingController.appendPage(state.list, currentPage + 1);
              } else {
                _userPagingController.appendLastPage(state.list);
              }
            } else {
              _userPagingController.appendLastPage([]);
            }
            _userPagingController.addPageRequestListener((pageKey) {
              if (_lastUserReview != null) {
                _profileBloc.add(
                  GetNextUserRatings(
                    userId: _lastUserReview!.userid!,
                    startAfterVal: _lastUserReview!.review_date!,
                    lastUserId: _lastUserReview!.userid!,
                  ),
                );
              }
            });
          }

          if (state is GetNextUserRatingsSuccess) {
            if (state.list.isNotEmpty) {
              _lastUserReview = state.list.last;
              if (state.list.length == productCount) {
                _userPagingController.appendPage(state.list, currentPage + 1);
              } else {
                _userPagingController.appendLastPage(state.list);
              }
            } else {
              _userPagingController.appendLastPage([]);
            }
          }
        },
        child: Column(
          children: [
            CustomAppBar(
              label: 'User Reviews',
            ),
            Expanded(
              child: _buildUserRatingsList(),
            ),
          ],
        ),
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
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreScreen(
                  userId: rating.reviewerid!,
                  userName: rating.reviewername!,
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
                      Expanded(
                        child: Text(
                          rating.reviewername ?? '',
                          style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        timeago.format(DateTime.parse(rating.review_date!)),
                        style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 10),
                      ),
                    ],
                  ),
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
                            Container(
                              height: 100.0,
                              width: double.infinity,
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
}
