import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

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
  List<ProductModel> _list = [];

  int currentPage = 0;

  List<ProductModel> indicators = [];

  @override
  void initState() {
    _productBloc.add(GetFirstProducts('user', userId: widget.userId));
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
                label: '${widget.userId}\'s Store',
              ),
              CustomSearchBar(
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                controller: TextEditingController(),
                backgroundColor: Color(0xFF005F73).withOpacity(0.3),
              ),
              Expanded(
                child: BlocListener(
                  bloc: _productBloc,
                  listener: (context, state) {
                    if (state is ProductLoading) {
                      ProgressHUD.of(context)!.show();
                    } else {
                      ProgressHUD.of(context)!.dismiss();
                    }

                    if (state is GetFirstProductsSuccess) {
                      setState(() {
                        currentPage = 0;
                        _list = state.list;
                        indicators.clear();
                        indicators.add(_list.last);
                      });
                    }

                    if (state is GetProductsSuccess) {
                      setState(() {
                        _list = state.list;

                        indicators.add(_list.last);
                      });
                      print('==== CURRENT PAGE: $currentPage');

                      indicators.asMap().forEach((key, value) =>
                          print('==== page $key: ${value.productid}'));
                    }
                  },
                  child: Container(
                    child: _list.isNotEmpty
                        ? GridView.count(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 10.0,
                            ),
                            crossAxisCount: 2,
                            mainAxisSpacing: 14.0,
                            crossAxisSpacing: 12.0,
                            children: _list
                                .map(
                                  (product) => Center(
                                    child: BarterListItem(
                                      hideLikeBtn: true,
                                      itemName: product.productname ?? '',
                                      itemPrice: product.price != null
                                          ? product.price!.toStringAsFixed(2)
                                          : '0',
                                      imageUrl: product.mediaPrimary != null &&
                                              product.mediaPrimary!.url !=
                                                  null &&
                                              product
                                                  .mediaPrimary!.url!.isNotEmpty
                                          ? product.mediaPrimary!.url!
                                          : '',
                                      onTapped: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailsScreen(
                                            productId: product.productid ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          )
                        : Container(
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
}
