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
import 'package:tapkat/widgets/custom_textformfield.dart';

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
  num? _origRequestedCash;
  num? _requestedCash;
  num? _origOfferedCash;
  num? _offeredCash;

  final amounTextController = TextEditingController();

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
    DialogMessage.dismiss();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    bool shouldExit = true;
    if (_offersChanged()) {
      final result = await DialogMessage.show(
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
    return shouldExit;
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
                listener: (context, state) async {
                  if (state is BarterLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is UpdateBarterProductsSuccess ||
                      state is DeleteBarterProductsSuccess ||
                      state is AddCashOfferSuccess) {
                    setState(() {
                      origOffers = List.from(offers);
                      origWants = List.from(wants);
                      _origOfferedCash = _offeredCash;
                      _origRequestedCash = _requestedCash;
                    });

                    if (this.mounted) {
                      await DialogMessage.show(
                        context,
                        title: 'Info',
                        message: widget.fromOtherUser
                            ? 'This offer has been sent'
                            : 'This proposal has been sent to $_participantName',
                        hideClose: true,
                      );
                    }
                  }

                  if (state is BarterInitialized) {
                    setState(() {
                      participantItems = state.user2Products;
                      userItems = state.userProducts;
                      state.barterProducts.forEach((bProduct) {
                        final _prod = ProductModel.fromJson(bProduct.toJson());
                        if (bProduct.productId!.contains('cash')) {
                          if (bProduct.userId == _currentUser!.uid) {
                            _origOfferedCash = bProduct.price;
                            _offeredCash = bProduct.price;
                          } else {
                            _origRequestedCash = bProduct.price;
                            _requestedCash = bProduct.price;
                          }
                        } else {
                          if (_prod.userid == _currentUser!.uid) {
                            wants.add(bProduct);
                            origWants.add(bProduct);
                          } else {
                            offers.add(bProduct);
                            origOffers.add(bProduct);
                          }
                        }
                      });
                    });
                    _barterStreamSub =
                        state.barterStream.listen((barterRecord) {
                      print(
                          'barter record from stream: ${barterRecord.toJson()}');
                      setState(() {
                        _barterRecord = barterRecord;
                        if (_barterId == null)
                          _barterId = _barterRecord!.barterId;
                      });
                    });
                  }

                  if (state is DeleteBarterSuccess) {
                    Navigator.pop(context);
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
                            final exit = await _onWillPop();
                            if (exit) {
                              Navigator.pop(context);
                            }
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
                              DialogMessage.show(
                                context,
                                title: 'Delete Barter',
                                message:
                                    'Are you sure you want to delete this Barter?',
                                buttonText: 'Yes',
                                firstButtonClicked: () =>
                                    _barterBloc.add(DeleteBarter(_barterId!)),
                                secondButtonText: 'No',
                                hideClose: true,
                              );
                            }
                          },
                          child: FaIcon(
                            Icons.delete_forever,
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
                              Visibility(
                                visible: widget.fromOtherUser,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    '$_participantName has proposed this deal',
                                    style: Style.bodyText1,
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  'Tap the (+) icon to add items on your barter, you can select multiple items from your gallery.',
                                  style: Style.bodyText1.copyWith(fontSize: 12),
                                ),
                              ),
                              _buildBarterList(
                                label: !widget.fromOtherUser
                                    ? 'You want these item(s) from $_participantName'
                                    : '$_participantName wants these item(s) from you',
                                items: [
                                  _requestedCash != null
                                      ? _buildCashItem(_requestedCash!)
                                      : Container(),
                                  ...wants.map((item) {
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
                                  }).toList()
                                ],
                                addBtnTapped: _showParticipantItems,
                              ),
                              _buildBarterList(
                                label: !widget.fromOtherUser
                                    ? 'Your offer'
                                    : 'Offers from $_participantName',
                                labelAction: Text(
                                  '${offers.length} Item(s) offered',
                                ),
                                items: [
                                  _offeredCash != null
                                      ? _buildCashItem(_offeredCash!)
                                      : Container(),
                                  ...offers.map((item) {
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
                                                  offers.removeWhere(
                                                      (product) =>
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
                                  }).toList()
                                ],
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
                    padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                label: _barterRecord != null
                                    ? _getGoBtnText()
                                    : '',
                                textColor: Colors.white,
                                onTap: _onSubmitTapped,
                                removeMargin: true,
                                enabled: _offersChanged(),
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              child: CustomButton(
                                label: widget.fromOtherUser
                                    ? 'Reject'
                                    : 'Withdraw',
                                bgColor: Color(0xFFBB3F03),
                                textColor: Colors.white,
                                onTap: _onCancelTapped,
                                removeMargin: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.0),
                        CustomButton(
                          label: 'Chat',
                          bgColor: kBackgroundColor,
                          textColor: Colors.white,
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
                          removeMargin: true,
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

  String _getGoBtnText() {
    switch (_barterRecord!.dealStatus) {
      case 'new':
        return widget.fromOtherUser ? 'Accept' : 'Make Offer';
      case 'submitted':
        return widget.fromOtherUser ? 'Send Request' : 'Make Offer';
      case 'accepted':
        return 'Mark as Sold';
      case 'sold':
        return 'Leave a review';
      default:
        return '';
    }
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
    if ((_origOfferedCash != _offeredCash) ||
        (_origRequestedCash != _requestedCash)) changed = true;

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

    if (_origOfferedCash != _offeredCash) {
      if (_offeredCash != null) {
        _barterBloc.add(
          AddCashOffer(
            barterId: _barterRecord!.barterId!,
            userId: _currentUser!.uid,
            amount: _offeredCash!,
            currency: 'PHP',
          ),
        );
      } else {
        // Delete Cash Offer
      }
    }

    if (_origRequestedCash != _requestedCash) {
      if (_requestedCash != null) {
        _barterBloc.add(
          AddCashOffer(
            barterId: _barterRecord!.barterId!,
            userId: _barterRecord!.userid2!,
            amount: _requestedCash!,
            currency: 'PHP',
          ),
        );
      } else {
        // Delete Request Cash
      }
    }

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

    switch (_barterRecord!.dealStatus) {
      case 'new':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        break;
      case 'submitted':
        if (widget.fromOtherUser)
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'accepted'));
        break;
      case 'accepted':
        _barterBloc.add(UpdateBarterStatus(_barterRecord!.barterId!, 'sold'));
        break;
      default:
    }
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
                    items: [
                      ...participantItems.map((item) {
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
                                            selectedItems.removeWhere(
                                                (product) =>
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
                    ],
                    showAddBtn: false,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Add Selected Item(s)',
                          enabled: selectedItems.length > 0,
                          bgColor: kBackgroundColor,
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
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: CustomButton(
                          label: _requestedCash != null
                              ? 'Edit Requested Cash'
                              : 'Request Cash',
                          bgColor: Color(0xFFBB3F03),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCashDialog('participant');
                          },
                          removeMargin: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  _showAddCashDialog(String from) async {
    if (from == 'participant') {
      amounTextController.text =
          _requestedCash != null ? _requestedCash.toString() : '';
    } else {
      amounTextController.text =
          _offeredCash != null ? _offeredCash.toString() : '';
    }
    final _cFormKey = GlobalKey<FormState>();
    var amount = await showDialog(
      context: context,
      builder: (dContext) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
            width: SizeConfig.screenWidth * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  from == 'participant' ? 'Request Cash' : 'Offer Cash',
                  style: Style.subtitle1.copyWith(color: kBackgroundColor),
                ),
                SizedBox(height: 10.0),
                Form(
                  key: _cFormKey,
                  child: CustomTextFormField(
                    color: kBackgroundColor,
                    label: 'Enter Amount',
                    hintText: '0.00',
                    controller: amounTextController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.length < 1) return 'Required';
                    },
                  ),
                ),
                SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        bgColor: kBackgroundColor,
                        textColor: Colors.white,
                        label: 'Send',
                        onTap: () {
                          if (!_cFormKey.currentState!.validate())
                            return null;
                          else {
                            final amount =
                                num.parse(amounTextController.text.trim());
                            amounTextController.clear();
                            Navigator.pop(context, amount);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: CustomButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(dContext),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    // await DialogMessage.show(
    //   context,
    //   title: from == 'participant' ? 'Request Cash' : 'Offer Cash',
    //   customMessage: Form(
    //     key: _cFormKey,
    //     child: CustomTextFormField(
    //       color: kBackgroundColor,
    //       label: 'Enter Amount',
    //       hintText: '0.00',
    //       controller: amounTextController,
    //       keyboardType: TextInputType.numberWithOptions(decimal: true),
    //       validator: (val) {
    //         if (val == null || val.length < 1) return 'Required';
    //       },
    //     ),
    //   ),
    //   buttonText: 'Send',
    //   secondButtonText: 'Cancel',
    //   firstButtonClicked: () {
    //     if (!_cFormKey.currentState!.validate())
    //       return null;
    //     else {
    //       final amount = num.parse(amounTextController.text.trim());
    //       amounTextController.clear();
    //       Navigator.pop(context, amount);
    //     }
    //   },
    //   secondButtonClicked: () {
    //     DialogMessage.dismiss();
    //   },
    // );

    if (amount != null) {
      amount = amount as num;

      setState(() {
        if (from == 'participant') {
          _requestedCash = amount;
        } else {
          _offeredCash = amount;
        }
      });
    }
  }

  _addWantedItems(List<BarterProductModel> items) {
    setState(() {
      wants.addAll(items);
    });
  }

  _add_offeredCashItems(List<BarterProductModel> items) {
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
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Add Selected Item(s)',
                          enabled: selectedItems.length > 0,
                          bgColor: kBackgroundColor,
                          textColor: Colors.white,
                          onTap: () {
                            _add_offeredCashItems(selectedItems
                                .map((item) =>
                                    BarterProductModel.fromProductModel(item))
                                .toList());
                            Navigator.pop(context);
                          },
                          removeMargin: true,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: CustomButton(
                          label: _offeredCash != null
                              ? 'Edit Offered Cash'
                              : 'Offer Cash',
                          bgColor: Color(0xFFBB3F03),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCashDialog('user');
                          },
                          removeMargin: true,
                        ),
                      ),
                    ],
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

  Widget _buildCashItem(num amount) {
    return InkWell(
      child: Container(
        height: 190.0,
        width: 160.0,
        margin: EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              offset: Offset(1, 1),
              color: Colors.grey.shade200,
              blurRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  color: Colors.white,
                  image: DecorationImage(
                    image: AssetImage('assets/images/cash_icon.png'),
                    fit: BoxFit.cover,
                    colorFilter:
                        ColorFilter.mode(kBackgroundColor, BlendMode.color),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10.0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Text(amount.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
