import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductRatingsScreen extends StatefulWidget {
  final ProductModel product;
  const ProductRatingsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductRatingsScreen> createState() => _ProductRatingsScreenState();
}

class _ProductRatingsScreenState extends State<ProductRatingsScreen> {
  final _productBloc = ProductBloc();
  late ProductModel product;

  List<ProductReviewModel> _ratings = [];

  final _pagingController =
      PagingController<int, ProductReviewModel>(firstPageKey: 0);

  ProductReviewModel? lastProduct;

  int currentPage = 0;

  @override
  void initState() {
    // TODO: implement initState
    product = widget.product;
    super.initState();
    _productBloc.add(GetProductRatings(widget.product));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        child: BlocListener(
          bloc: _productBloc,
          listener: (context, state) {
            if (state is ProductLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetProductRatingsSucess) {
              // setState(() {
              //   _ratings = state.list;
              // });

              if (state.list.isNotEmpty) {
                lastProduct = state.list.last;
                if (state.list.length == productCount) {
                  setState(() {
                    _ratings.addAll(state.list);
                  });
                  _pagingController.appendPage(state.list, currentPage + 1);
                } else {
                  setState(() {
                    _ratings.addAll(state.list);
                  });
                  _pagingController.appendLastPage(state.list);
                }
              } else {
                print('lastrProduct name: ${lastProduct!.productname}');
                _pagingController.addPageRequestListener((pageKey) {
                  if (lastProduct != null) {
                    _productBloc.add(
                      GetNextRatings(
                        productId: lastProduct!.productid!,
                        startAfterVal: lastProduct!.rating!.toDouble(),
                        lastUserId: lastProduct!.userid!,
                      ),
                    );
                  }
                });
              }
            }
          },
          child: Column(
            children: [
              CustomAppBar(
                label: 'Product Ratings',
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: SizeConfig.screenWidth * .3,
                      height: SizeConfig.screenWidth * .3,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: product.mediaPrimary != null
                              ? NetworkImage(product.mediaPrimary!.url!)
                              : AssetImage(
                                      'assets/images/image_placeholder.jpg')
                                  as ImageProvider<Object>,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productname ?? '',
                              style: Style.subtitle2.copyWith(
                                color: kBackgroundColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              product.price == null
                                  ? ''
                                  : '\$ ${product.price!.toStringAsFixed(2)}',
                              style: Style.subtitle2.copyWith(
                                color: kBackgroundColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  size: 20.0,
                                  color: kBackgroundColor,
                                ),
                                Text(
                                  product.address!.address!.isNotEmpty
                                      ? product.address!.address!
                                      : 'No address',
                                  style: Style.subtitle2
                                      .copyWith(color: kBackgroundColor),
                                )
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                RatingBar.builder(
                                  ignoreGestures: true,
                                  initialRating: product.rating != null
                                      ? product.rating!.roundToDouble()
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
                                Text(
                                  product.rating != null
                                      ? product.rating!.toStringAsFixed(1)
                                      : '0',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: _ratings.map((rating) {
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
                                  Text(timeago.format(
                                      rating.review_date ?? DateTime.now())),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(rating.review != null &&
                                        rating.review!.isNotEmpty
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
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
