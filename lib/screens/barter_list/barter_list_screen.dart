import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

class BarterListScreen extends StatefulWidget {
  final bool showAdd;

  final String listType;
  final String? userId;

  const BarterListScreen({
    Key? key,
    required this.listType,
    this.userId,
    this.showAdd = false,
  }) : super(key: key);

  @override
  _BarterListScreenState createState() => _BarterListScreenState();
}

class _BarterListScreenState extends State<BarterListScreen> {
  final _productBloc = ProductBloc();
  late String _title;
  List<ProductModel> _list = [];

  int currentPage = 0;

  List<ProductModel> indicators = [];

  @override
  void initState() {
    _setTitle();
    _productBloc.add(GetFirstProducts(widget.listType, userId: widget.userId));
    super.initState();
  }

  void _setTitle() {
    switch (widget.listType) {
      case 'reco':
        _title = 'Recommended For You';
        break;
      case 'demand':
        _title = 'People are Looking For';
        break;
      default:
        _title = 'Your items';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xFFEBFBFF),
      body: ProgressHUD(
        barrierEnabled: true,
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
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

              indicators.asMap().forEach(
                  (key, value) => print('==== page $key: ${value.productid}'));
            }
          },
          child: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: _title,
                ),
                CustomSearchBar(
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  controller: TextEditingController(),
                  backgroundColor: Color(0xFF005F73).withOpacity(0.3),
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
                            mainAxisSpacing: 14.0,
                            crossAxisSpacing: 12.0,
                            children: _list
                                .map((product) => Center(
                                      child: BarterListItem(
                                        itemName: product.productname ?? '',
                                        itemPrice: product.price != null
                                            ? product.price.toString()
                                            : '',
                                        imageUrl: product.mediaPrimary != null
                                            ? product.mediaPrimary!.url ?? ''
                                            : '',
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
                                      ),
                                    ))
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
                                  SizedBox(height: 16.0),
                                  Visibility(
                                    visible: widget.showAdd,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30.0),
                                      child: CustomButton(
                                        label: 'Add Product',
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductAddScreen(),
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
                ),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
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
                                color:
                                    _list.isEmpty ? Colors.grey : Colors.white,
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
      ),
    );
  }

  void _onNextTapped() {
    print('next tapped, current page $currentPage');
    if (_list.isEmpty) return;

    _productBloc.add(
      GetNextProducts(
        listType: widget.listType,
        lastProductId: _list.last.productid!,
        startAfterVal: _list.last.price!.toString(),
      ),
    );

    setState(() {
      currentPage += 1;
    });
  }

  void _onPrevTapped() {
    if (currentPage < 1) return;

    if (currentPage == 1) _productBloc.add(GetFirstProducts(widget.listType));

    if (currentPage > 1) {
      _productBloc.add(GetNextProducts(
          listType: widget.listType,
          lastProductId: indicators[currentPage - 2].productid!,
          startAfterVal: indicators[currentPage - 2].price!.toString()));
    }

    setState(() {
      currentPage -= 1;
    });
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
