import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/screens/product/product_trade_for_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/utilities/application.dart' as application;

import 'bloc/product_bloc.dart';

class SelectProductCategoryScreen extends StatefulWidget {
  final bool updating;
  final ProductRequestModel productRequest;
  final List<SelectedMedia>? media;
  final List<ProductCategoryModel> categories;
  const SelectProductCategoryScreen({
    Key? key,
    required this.productRequest,
    this.media,
    required this.categories,
    this.updating = false,
  }) : super(key: key);

  @override
  State<SelectProductCategoryScreen> createState() =>
      _SelectProductCategoryScreenState();
}

class _SelectProductCategoryScreenState
    extends State<SelectProductCategoryScreen> {
  final _productBloc = ProductBloc();
  List<ProductCategoryModel> _categories = [];
  List<ProductCategoryModel> _selectedCategories = [];
  ProductCategoryModel? _selectedCategory;

  @override
  void initState() {
    application.currentScreen = 'Product Select Categories Screen';
    // TODO: implement initState
    _categories.addAll(widget.categories);
    print(widget.productRequest.toJson());
    if (widget.productRequest.category != null &&
        widget.productRequest.category!.isNotEmpty) {
      setState(() {
        _selectedCategory = _categories
            .firstWhere((cat) => cat.code == widget.productRequest.category);
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        child: BlocListener(
          bloc: _productBloc,
          listener: (context, state) async {
            if (state is ProductLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is SaveProductSuccess) {
              await DialogMessage.show(context,
                  message: 'An offer has been added');

              // Navigator.of(context).popUntil((route) => route.isFirst);
              var count = 0;
              Navigator.popUntil(context, (route) {
                return count++ == 2;
              });
            }

            if (state is EditProductSuccess) {
              await DialogMessage.show(context,
                  message: 'The product has been updated.');

              var count = 0;
              Navigator.popUntil(context, (route) {
                return count++ == 2;
              });
            }
          },
          child: Container(
            color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: widget.updating ? 'Edit Product' : 'Add to Your Store',
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500.0),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: [
                        SizeConfig.screenWidth > 500
                            ? SizedBox(height: SizeConfig.screenHeight * 0.1)
                            : SizedBox(),
                        Text('Select category of your product'),
                        _categories.isNotEmpty
                            ? Expanded(
                                child: GridView.count(
                                  padding: EdgeInsets.only(top: 20.0),
                                  shrinkWrap: true,
                                  childAspectRatio: 3 / 2,
                                  mainAxisSpacing: 10.0,
                                  crossAxisSpacing: 10.0,
                                  crossAxisCount: 3,
                                  children: _categories
                                      .where((cat) =>
                                          cat.type ==
                                          widget.productRequest.type)
                                      .map((cat) => Center(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedCategory = cat;
                                                  // if (_selectedCategories
                                                  //     .contains(cat))
                                                  //   _selectedCategories
                                                  //       .remove(cat);
                                                  // else
                                                  //   _selectedCategories
                                                  //       .add(cat);
                                                });
                                              },
                                              child: Container(
                                                height:
                                                    SizeConfig.screenHeight *
                                                        .08,
                                                width: SizeConfig.screenWidth *
                                                    .25,
                                                padding: EdgeInsets.all(3.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  color:
                                                      _selectedCategory == cat
                                                          ? kBackgroundColor
                                                          : Color(0xFFEBFBFF),
                                                  border: _selectedCategory ==
                                                          cat
                                                      ? null
                                                      : Border.all(
                                                          color:
                                                              kBackgroundColor),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    cat.name ?? '',
                                                    style: TextStyle(
                                                      color: _selectedCategory ==
                                                              cat
                                                          ? Colors.white
                                                          : kBackgroundColor,
                                                      fontSize: SizeConfig
                                                                  .screenWidth >
                                                              500
                                                          ? SizeConfig
                                                                  .textScaleFactor *
                                                              16
                                                          : SizeConfig
                                                                  .textScaleFactor *
                                                              11,
                                                      height: 1.2,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: CustomButton(
                    removeMargin: true,
                    label: 'Next',
                    onTap: _onSaveTapped,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onSaveTapped() async {
    var productRequest = widget.productRequest;
    productRequest.category =
        _selectedCategory != null ? _selectedCategory!.code : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductTradeForScreen(
          updating: widget.updating,
          productRequest: productRequest,
          media: widget.media,
        ),
      ),
    );
  }
}
