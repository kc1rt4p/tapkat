import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';

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
  List<ProductCategoryModel> _categories = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _categories.addAll(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    final _productBloc = ProductBloc();
    return Scaffold(
      body: ProgressHUD(
        child: BlocListener(
          bloc: _productBloc,
          listener: (context, state) {
            // TODO: implement listener
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
                      horizontal: 30.0,
                      vertical: 10.0,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          //
                        ],
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
}
