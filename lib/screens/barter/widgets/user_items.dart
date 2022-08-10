import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/barter_repository.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_button.dart';

class UserItemsDialog extends StatefulWidget {
  final String recipientUserId;
  final String recipientName;
  final String userId;
  final String userType;
  final List<String> selectedProducts;
  final String barterId;
  const UserItemsDialog({
    Key? key,
    required this.userId,
    required this.recipientUserId,
    required this.recipientName,
    required this.userType,
    required this.selectedProducts,
    required this.barterId,
  }) : super(key: key);

  @override
  State<UserItemsDialog> createState() => _UserItemsDialogState();
}

class _UserItemsDialogState extends State<UserItemsDialog> {
  final _productBloc = ProductBloc();
  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);
  ProductModel? lastProduct;
  int currentPage = 0;
  List<ProductModel> _selectedProducts = [];
  final _barterRepo = BarterRepository();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _productBloc.add(GetFirstProducts(
      listType: 'user',
      userid: widget.userId,
      sortBy: 'distance',
      distance: 50000,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _productBloc,
      listener: (context, state) {
        if (state is GetFirstProductsSuccess) {
          if (state.list.isNotEmpty) {
            lastProduct = state.list.last;
            if (state.list.length == productCount) {
              _pagingController.appendPage(
                  state.list
                      .where((prod) => prod.status != 'completed')
                      .toList(),
                  currentPage + 1);
            } else {
              _pagingController.appendLastPage(state.list
                  .where((prod) => prod.status != 'completed')
                  .toList());
            }

            _pagingController.addPageRequestListener((pageKey) {
              if (lastProduct != null) {
                _productBloc.add(
                  GetNextProducts(
                    listType: 'user',
                    lastProductId: lastProduct!.productid!,
                    sortBy: 'distance',
                    distance: 50000,
                    startAfterVal: lastProduct!.price.toString(),
                    userId: widget.userId,
                  ),
                );
              }
            });
          }
        }

        if (state is GetProductsSuccess) {
          if (state.list.isNotEmpty) {
            lastProduct = state.list
                .where((prod) => prod.status != 'completed')
                .toList()
                .last;
            if (state.list.length == productCount) {
              _pagingController.appendPage(
                  state.list
                      .where((prod) => prod.status != 'completed')
                      .toList(),
                  currentPage + 1);
            } else {
              _pagingController.appendLastPage(state.list
                  .where((prod) => prod.status != 'completed')
                  .toList());
            }
          } else {
            _pagingController.appendLastPage([]);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.userType} Store',
                      style: Style.subtitle1.copyWith(color: kBackgroundColor),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context, null),
                    child: Container(
                        padding: EdgeInsets.only(
                          left: 10.0,
                        ),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                        )),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10.0),
              constraints: BoxConstraints(maxWidth: 500.0),
              height: SizeConfig.screenHeight * 0.5,
              child: PagedGridView(
                pagingController: _pagingController,
                showNewPageProgressIndicatorAsGridChild: false,
                showNewPageErrorIndicatorAsGridChild: false,
                showNoMoreItemsIndicatorAsGridChild: false,
                builderDelegate: PagedChildBuilderDelegate<ProductModel>(
                  itemBuilder: (context, product, index) {
                    final bool _added = widget.selectedProducts
                        .any((prod) => prod == product.productid);
                    final bool _selected = _selectedProducts
                        .any((prod) => prod.productid == product.productid);

                    return FutureBuilder(
                      future: _barterRepo.checkIfBarterable(
                          widget.recipientUserId,
                          product.productid!,
                          widget.barterId),
                      builder: (context, snapshot) {
                        print('X===> ${snapshot.data}');
                        if (snapshot.connectionState == ConnectionState.done) {
                          final barterable = snapshot.data as bool? ?? false;
                          return FittedBox(
                            child: Stack(
                              children: [
                                BarterListItem(
                                  product: product,
                                  onTapped: () async {
                                    if (!barterable) {
                                      await DialogMessage.show(
                                        context,
                                        message:
                                            'You can\'t add this product to the barter as you already have a another pending barter with ${widget.recipientName.toUpperCase()} for this ${product.productname}',
                                      );

                                      return;
                                    }
                                    if (_added || _selected) return;
                                    setState(() {
                                      _selectedProducts.add(product);
                                    });
                                  },
                                  hideLikeBtn: true,
                                  showRating: false,
                                  hideDistance: true,
                                ),
                                Visibility(
                                  visible: !barterable,
                                  child: Positioned.fill(
                                    bottom: 0,
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 5.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'UNAVAILABLE',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize:
                                                SizeConfig.textScaleFactor * 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: _added || _selected,
                                  child: Positioned.fill(
                                    child: InkWell(
                                      onTap: () async {
                                        if (_added) return;
                                        setState(() {
                                          _selectedProducts.remove(product);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                        ),
                                        child: Center(
                                            child: _added
                                                ? Text(
                                                    'ADDED',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : Icon(
                                                    FontAwesomeIcons.check,
                                                    color: Colors.white,
                                                    size: 35.0,
                                                  )),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return FittedBox(
                          child: Shimmer.fromColors(
                            highlightColor: kBackgroundColor,
                            baseColor: kBackgroundColor.withOpacity(0.8),
                            child: Container(
                              height: SizeConfig.screenHeight * 0.17,
                              width: SizeConfig.screenHeight * 0.15,
                              decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: SizeConfig.screenWidth > 500 ? 3 : 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
              ),
            ),
            CustomButton(
              enabled: _selectedProducts.isNotEmpty,
              removeMargin: true,
              label: 'Add Item(s)',
              onTap: () => Navigator.pop(context, _selectedProducts),
            ),
          ],
        ),
      ),
    );
  }
}
