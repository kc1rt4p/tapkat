import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/barter/barter_chat_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_button.dart';

import 'bloc/barter_bloc.dart';

class BarterScreen extends StatefulWidget {
  final ProductModel? product;
  final BarterRecordModel? barterRecord;
  final bool fromOtherUser;

  const BarterScreen({
    Key? key,
    this.product,
    this.barterRecord,
    this.fromOtherUser = false,
  }) : super(key: key);

  @override
  _BarterScreenState createState() => _BarterScreenState();
}

class _BarterScreenState extends State<BarterScreen> {
  ProductModel? _product;
  late AuthBloc _authBloc;
  final _barterBloc = BarterBloc();
  List<BarterProductModel> origOffers = [];
  List<BarterProductModel> offers = [];
  List<BarterProductModel> origWants = [];
  List<BarterProductModel> wants = [];
  late String _participantName;
  List<ProductModel> participantItems = [];
  List<ProductModel> userItems = [];
  User? _currentUser;
  BarterRecordModel? _barterRecord;
  StreamSubscription<BarterRecordModel>? _barterStreamSub;
  String? _barterId;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());
    if (widget.product != null) {
      _product = widget.product!;
      _participantName = _product!.userid ?? '';
      _participantName = _participantName[0].toUpperCase() +
          _participantName.substring(1).toLowerCase();
    } else {
      _participantName = widget.barterRecord!.userid1 ?? '';
      _participantName = _participantName[0].toUpperCase() +
          _participantName.substring(1).toLowerCase();
    }

    if (widget.barterRecord != null) {
      // print('barter record: ${widget.barterRecord!.toJson()}');
      // setState(() {
      //   _barterId = widget.barterRecord!.barterId;
      //   wants.add(ProductModel(
      //     productid: widget.barterRecord!.u1P1Id,
      //     productname: widget.barterRecord!.u1P1Name,
      //     price: widget.barterRecord!.u1P1Price,
      //     mediaPrimary: MediaPrimaryModel(
      //       type: 'image',
      //       url: widget.barterRecord!.u1P1Image,
      //     ),
      //   ));
      // });
    }

    _participantName = _participantName.length > 10
        ? _participantName.substring(0, 10) + '...'
        : _participantName;

    super.initState();
  }

  @override
  void dispose() {
    _barterStreamSub?.cancel();
    _barterStreamSub = null;

    super.dispose();
  }

  Future<bool> _onWillPop() async {
    print(_offersChanged());
    if (_offersChanged()) {
      await DialogMessage.show(
        context,
        title: 'Warning',
        message: 'Changes were made, do you want to send your offers?',
        buttonText: 'Yes',
        firstButtonClicked: () {
          _onSubmitTapped();
        },
        secondButtonText: 'No',
        hideClose: true,
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Color(0xFFEBFBFF),
        body: ProgressHUD(
          indicatorColor: kBackgroundColor,
          backgroundColor: Colors.white,
          barrierEnabled: false,
          child: MultiBlocListener(
            listeners: [
              BlocListener(
                bloc: _barterBloc,
                listener: (context, state) {
                  if (state is BarterLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is UpdateBarterProductsSuccess ||
                      state is DeleteBarterProductsSuccess) {
                    setState(() {
                      origOffers = List.from(offers);
                      origWants = List.from(wants);
                    });
                  }

                  if (state is BarterInitialized) {
                    setState(() {
                      participantItems = state.user2Products;
                      userItems = state.userProducts;
                      state.barterProducts.forEach((bProduct) {
                        final _prod = ProductModel.fromJson(bProduct.toJson());
                        if (_prod.userid == _currentUser!.uid) {
                          offers.add(bProduct);
                          origOffers.add(bProduct);
                        } else {
                          wants.add(bProduct);
                          origWants.add(bProduct);
                        }
                      });
                    });
                    _barterStreamSub =
                        state.barterStream.listen((barterRecord) {
                      print(
                          'barter record from stream: ${barterRecord.toJson()}');
                      setState(() {
                        _barterRecord = barterRecord;
                      });
                    });
                  }

                  if (state is BarterError) {
                    print('error: ${state.message}');
                  }
                },
              ),
              BlocListener(
                bloc: _authBloc,
                listener: (context, state) {
                  print('auth bloc current state: $state');
                  if (state is AuthLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }
                  if (state is GetCurrentUsersuccess) {
                    setState(() {
                      _currentUser = state.user;
                    });

                    if (widget.barterRecord == null && _product != null) {
                      _barterId = _currentUser!.uid +
                          _product!.userid! +
                          _product!.productid!;

                      _barterBloc.add(
                        InitializeBarter(
                          BarterRecordModel(
                            barterId: _barterId,
                            userid1: _currentUser!.uid,
                            userid2: _product!.userid,
                            u2P1Id: _product!.productid!,
                            u2P1Name: _product!.productname,
                            u2P1Price: _product!.price!.toDouble(),
                            u2P1Image: _product!.mediaPrimary!.url!,
                            barterNo: 0,
                            dealDate: DateTime.now(),
                          ),
                        ),
                      );
                    } else {
                      _barterBloc.add(StreamBarter(widget.barterRecord!));
                    }
                  }
                },
              ),
            ],
            child: Container(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        16.0, SizeConfig.paddingTop, 16.0, 0),
                    height: kToolbarHeight + SizeConfig.paddingTop,
                    color: kBackgroundColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await _onWillPop();
                            Navigator.pop(context);
                          },
                          child: FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Barter with $_participantName',
                          style: Style.subtitle1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_barterId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BarterChatScreen(
                                    barterId: _barterId!,
                                  ),
                                ),
                              );
                            }
                          },
                          child: FaIcon(
                            Icons.mail,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  'Tap the (+) icon to add items on your barter, you can select multiple items from your gallery.',
                                  style: Style.bodyText1,
                                ),
                              ),
                              _buildBarterList(
                                label: !widget.fromOtherUser
                                    ? 'You want these item(s) from $_participantName'
                                    : '$_participantName wants these item(s) from you',
                                items: wants.map((item) {
                                  return Container(
                                    margin: EdgeInsets.only(
                                        right: 8.0, bottom: 5.0),
                                    child: Stack(
                                      children: [
                                        BarterListItem(
                                          hideLikeBtn: true,
                                          itemName: item.productName ?? '',
                                          itemPrice: (item.currency ?? '\$') +
                                              (item.price != null
                                                  ? ' ${item.price!.toStringAsFixed(2)}'
                                                  : '0.00'),
                                          imageUrl: item.imgUrl != null &&
                                                  item.imgUrl!.isNotEmpty
                                              ? item.imgUrl!
                                              : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                                        ),
                                        Positioned(
                                          top: 5.0,
                                          right: 5.0,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                wants.removeWhere((product) =>
                                                    product.productId ==
                                                    item.productId);
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(5.0),
                                              decoration: BoxDecoration(
                                                color: kBackgroundColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  FontAwesomeIcons.times,
                                                  size: 16.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                addBtnTapped: _showParticipantItems,
                              ),
                              _buildBarterList(
                                label: !widget.fromOtherUser
                                    ? 'Your offer'
                                    : 'Offers from $_participantName',
                                labelAction: Text(
                                  '${offers.length} Item(s) Offered',
                                ),
                                items: offers.map((item) {
                                  return Container(
                                    margin: EdgeInsets.only(
                                        right: 8.0, bottom: 5.0),
                                    child: Stack(
                                      children: [
                                        BarterListItem(
                                          hideLikeBtn: true,
                                          itemName: item.productName ?? '',
                                          itemPrice: (item.currency ?? '\$') +
                                              (item.price != null
                                                  ? ' ${item.price!.toStringAsFixed(2)}'
                                                  : '0.00'),
                                          imageUrl: item.imgUrl != null &&
                                                  item.imgUrl!.isNotEmpty
                                              ? item.imgUrl!
                                              : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                                        ),
                                        Positioned(
                                          top: 5.0,
                                          right: 5.0,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                offers.removeWhere((product) =>
                                                    product.productId ==
                                                    item.productId);
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(5.0),
                                              decoration: BoxDecoration(
                                                color: kBackgroundColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  FontAwesomeIcons.times,
                                                  size: 16.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                addBtnTapped: _showUserItems,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                label:
                                    !widget.fromOtherUser ? 'Send' : 'Accept',
                                textColor: Colors.white,
                                onTap: _onSubmitTapped,
                                removeMargin: true,
                                enabled: _offersChanged(),
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: CustomButton(
                                label:
                                    !widget.fromOtherUser ? 'Cancel' : 'Reject',
                                bgColor: Color(0xFFBB3F03),
                                textColor: Colors.white,
                                onTap: () {},
                                removeMargin: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '$_participantName will be notified once you send this proposal',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
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
      ),
    );
  }

  bool _offersChanged() {
    bool changed = false;
    origOffers.forEach((oOffer) {
      final stillExists =
          offers.any((offer) => offer.productId == oOffer.productId);
      if (!stillExists) changed = true;
    });

    origWants.forEach((oWant) {
      final stillExists =
          wants.any((want) => want.productId == oWant.productId);
      if (!stillExists) changed = true;
    });

    if ((origOffers.length != offers.length) ||
        (origWants.length != wants.length)) changed = true;

    return changed;
  }

  _onSubmitTapped() {
    List<BarterProductModel> _deletedProducts = [];
    if (origOffers.length > offers.length) {
      origOffers.forEach((bProd) {
        if (!offers.any((obProd) => obProd.productId == bProd.productId)) {
          _deletedProducts.add(bProd);
        }
      });
    }

    if (origWants.length > wants.length) {
      origWants.forEach((owProd) {
        if (!offers.any((oProd) => oProd.productId == owProd.productId)) {
          _deletedProducts.add(owProd);
        }
      });
    }

    print('no. of delete items: ${_deletedProducts.length}');

    if (_deletedProducts.length > 0) {
      _barterBloc.add(DeleteBarterProducts(
        barterId: _barterRecord!.barterId!,
        products: _deletedProducts,
      ));
    }

    _barterBloc.add(UpdateBarterProducts(
      barterId: _barterRecord!.barterId!,
      products: wants + offers,
    ));
  }

  _onCancelTapped() {
    //
  }

  Container _buildBarterList({
    required String label,
    required List<Widget> items,
    Widget? labelAction,
    bool showAddBtn = true,
    Function()? addBtnTapped,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Style.subtitle2.copyWith(
                      color: kBackgroundColor, fontWeight: FontWeight.bold),
                ),
              ),
              labelAction ?? Container(),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 10.0),
                  ...items,
                  Visibility(
                    visible: showAddBtn,
                    child: _buildAddItemBtn(
                      onTap: addBtnTapped ?? () {},
                    ),
                  ),
                  SizedBox(width: 10.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _showParticipantItems() {
    showMaterialModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          List<ProductModel> selectedItems = [];
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  topLeft: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBarterList(
                    label: 'Select item(s) from $_participantName',
                    labelAction: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        FontAwesomeIcons.times,
                        color: kBackgroundColor,
                      ),
                    ),
                    items: participantItems.map((item) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 8.0, bottom: 5.0),
                            child: BarterListItem(
                              hideLikeBtn: true,
                              itemName: item.productname ?? '',
                              itemPrice: (item.currency != null
                                      ? item.currency!
                                      : '\$') +
                                  (' ${item.price!.toStringAsFixed(2)}'),
                              imageUrl: item.mediaPrimary != null &&
                                      item.mediaPrimary!.url != null
                                  ? item.mediaPrimary!.url!
                                  : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                              onTapped: () {
                                if (wants.any((product) =>
                                    product.productId == item.productid))
                                  return;

                                if (!selectedItems.any((want) =>
                                    want.productid == item.productid)) {
                                  setState(() {
                                    selectedItems.add(item);
                                  });
                                }
                              },
                            ),
                          ),
                          Visibility(
                            visible: wants.any((product) =>
                                product.productId == item.productid),
                            child: Container(
                              margin: EdgeInsets.only(right: 8.0),
                              width: 160.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                                color: Color(0xFFBB3F03),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              child: Center(
                                child: Text(
                                  'ADDED',
                                  style: Style.bodyText2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: selectedItems.any((product) =>
                                product.productid == item.productid),
                            child: Container(
                              margin: EdgeInsets.only(right: 8.0),
                              width: 160.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                                color: kBackgroundColor,
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              child: Center(
                                child: Row(
                                  children: [
                                    Text(
                                      'SELECTED',
                                      style: Style.bodyText2.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedItems.removeWhere((product) =>
                                              product.productid ==
                                              item.productid);
                                        });
                                      },
                                      child: Icon(
                                        FontAwesomeIcons.times,
                                        color: Colors.white,
                                        size: 16.0,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    showAddBtn: false,
                  ),
                  CustomButton(
                    label: 'Add Items',
                    bgColor: Color(0xFFBB3F03),
                    textColor: Colors.white,
                    onTap: () {
                      _addWantedItems(selectedItems
                          .map((item) =>
                              BarterProductModel.fromProductModel(item))
                          .toList());
                      Navigator.pop(context);
                    },
                    removeMargin: true,
                  ),
                ],
              ),
            );
          });
        });
  }

  _addWantedItems(List<BarterProductModel> items) {
    setState(() {
      wants.addAll(items);
    });
  }

  _addOfferedItems(List<BarterProductModel> items) {
    setState(() {
      offers.addAll(items);
    });
  }

  _showUserItems() {
    showMaterialModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          List<ProductModel> selectedItems = [];
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  topLeft: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBarterList(
                    label: !widget.fromOtherUser
                        ? 'Select your offer(s)'
                        : 'Select items from $_participantName',
                    labelAction: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        FontAwesomeIcons.times,
                        color: kBackgroundColor,
                      ),
                    ),
                    items: userItems.map((item) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 8.0, bottom: 5.0),
                            child: BarterListItem(
                              hideLikeBtn: true,
                              itemName: item.productname ?? '',
                              itemPrice: (item.currency != null &&
                                          item.currency!.isNotEmpty
                                      ? item.currency!
                                      : '\$') +
                                  (' ${item.price!.toStringAsFixed(2)}'),
                              imageUrl: item.mediaPrimary != null &&
                                      item.mediaPrimary!.url != null
                                  ? item.mediaPrimary!.url!
                                  : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                              onTapped: () {
                                if (!selectedItems.any((want) =>
                                    want.productid == item.productid)) {
                                  setState(() {
                                    selectedItems.add(item);
                                  });
                                }
                              },
                            ),
                          ),
                          Visibility(
                            visible: offers.any((product) =>
                                product.productId == item.productid),
                            child: Container(
                              margin: EdgeInsets.only(right: 8.0),
                              width: 160.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                                color: Color(0xFFBB3F03),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              child: Center(
                                child: Row(
                                  children: [
                                    Text(
                                      'ADDED',
                                      style: Style.bodyText2.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: selectedItems.any((product) =>
                                product.productid == item.productid),
                            child: Container(
                              margin: EdgeInsets.only(right: 8.0),
                              width: 160.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20.0),
                                  topRight: Radius.circular(20.0),
                                ),
                                color: kBackgroundColor,
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              child: Center(
                                child: Row(
                                  children: [
                                    Text(
                                      'SELECTED',
                                      style: Style.bodyText2.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedItems.removeWhere((product) =>
                                              product.productid ==
                                              item.productid);
                                        });
                                      },
                                      child: Icon(
                                        FontAwesomeIcons.times,
                                        color: Colors.white,
                                        size: 16.0,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    showAddBtn: false,
                  ),
                  CustomButton(
                    label: 'Add Items',
                    bgColor: Color(0xFFBB3F03),
                    textColor: Colors.white,
                    onTap: () {
                      _addOfferedItems(selectedItems
                          .map((item) =>
                              BarterProductModel.fromProductModel(item))
                          .toList());
                      Navigator.pop(context);
                    },
                    removeMargin: true,
                  ),
                ],
              ),
            );
          });
        });
  }

  InkWell _buildAddItemBtn({
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 190.0,
        width: 170.0,
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              offset: Offset(1, 1),
              color: Colors.grey,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            FontAwesomeIcons.plus,
            color: Colors.white,
            size: 40.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBarterListItem({
    required String itemName,
    required String itemPrice,
    required String imgUrl,
    Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, right: 16.0),
      child: Stack(
        children: [
          BarterListItem(
            itemName: itemName,
            itemPrice: itemPrice,
            imageUrl: imgUrl,
            hideLikeBtn: true,
          ),
          Positioned(
            top: 0.0,
            right: 0.0,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 30.0,
                width: 30.0,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.times,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
