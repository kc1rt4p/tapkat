import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

import 'bloc/product_bloc.dart';

class SelectProductCategoryScreen extends StatefulWidget {
  final ProductRequestModel productRequest;
  final List<SelectedMedia> media;
  final List<ProductCategoryModel> categories;
  const SelectProductCategoryScreen({
    Key? key,
    required this.productRequest,
    required this.media,
    required this.categories,
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

  @override
  void initState() {
    // TODO: implement initState
    _categories.addAll(widget.categories);
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

              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: Container(
            color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Add to Your Store',
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: [
                        Text('Select categories for your product'),
                        _categories.isNotEmpty
                            ? Expanded(
                                child: GridView.count(
                                  padding: EdgeInsets.only(top: 20.0),
                                  shrinkWrap: true,
                                  childAspectRatio: 3 / 2,
                                  mainAxisSpacing: 5.0,
                                  crossAxisCount: 3,
                                  children: _categories
                                      .where((cat) =>
                                          widget.productRequest.type == 'PT1'
                                              ? cat.code!.contains('PC')
                                              : cat.code!.contains('SC'))
                                      .map((cat) => Center(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (_selectedCategories
                                                      .contains(cat))
                                                    _selectedCategories
                                                        .remove(cat);
                                                  else
                                                    _selectedCategories
                                                        .add(cat);
                                                });
                                              },
                                              child: Container(
                                                height:
                                                    SizeConfig.screenHeight *
                                                        .08,
                                                width: SizeConfig.screenWidth *
                                                    .25,
                                                padding: EdgeInsets.all(10.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  color: _selectedCategories
                                                          .contains(cat)
                                                      ? kBackgroundColor
                                                      : Color(0xFFEBFBFF),
                                                  border: _selectedCategories
                                                          .contains(cat)
                                                      ? null
                                                      : Border.all(
                                                          color:
                                                              kBackgroundColor),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    cat.name ?? '',
                                                    style: TextStyle(
                                                      color: _selectedCategories
                                                              .contains(cat)
                                                          ? Colors.white
                                                          : kBackgroundColor,
                                                      fontSize: SizeConfig
                                                              .textScaleFactor *
                                                          13,
                                                      fontWeight:
                                                          FontWeight.w800,
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
                    enabled: _selectedCategories.length > 0,
                    label: 'Save',
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

  _onSaveTapped() {
    var productRequest = widget.productRequest;
    productRequest.category =
        _selectedCategories.map((sc) => sc.code ?? '').toList();
    _productBloc.add(SaveProduct(
      media: widget.media,
      productRequest: productRequest,
    ));
  }
}
