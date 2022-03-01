import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/barter/widgets/add_item_btn.dart';
import 'package:tapkat/screens/barter/widgets/cash_item.dart';
import 'package:tapkat/screens/barter/widgets/chat_item.dart';
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

  const BarterScreen({
    Key? key,
    this.product,
    this.barterRecord,
  }) : super(key: key);

  @override
  _BarterScreenState createState() => _BarterScreenState();
}

class _BarterScreenState extends State<BarterScreen> {
  final unsaveProductsStorage = new LocalStorage('unsaved_products.json');
  ProductModel? _product;

  late AuthBloc _authBloc;
  final _barterBloc = BarterBloc();

  List<BarterProductModel> origOffers = [];
  List<BarterProductModel> offers = [];
  List<BarterProductModel> origWants = [];
  List<BarterProductModel> wants = [];

  List<ProductModel> participantItems = [];
  List<ProductModel> userItems = [];

  String _recipientName = '';
  String? _barterId;

  User? _currentUser;
  BarterRecordModel? _barterRecord;
  StreamSubscription<BarterRecordModel?>? _barterStreamSub;
  StreamSubscription<List<BarterProductModel>>? _barterProductsStream;
  num? _origRequestedCash;
  num? _requestedCash;
  num? _origOfferedCash;
  num? _offeredCash;
  BarterProductModel? _offeredCashModel;
  BarterProductModel? _requestedCashModel;

  final amounTextController = TextEditingController();
  final _messageTextController = TextEditingController();
  final _panelController = PanelController();
  bool _panelClosed = true;

  List<ChatMessageModel> _messages = [];
  StreamSubscription<List<ChatMessageModel?>>? _barterChatStreamSub;
  bool _closing = false;

  final _chatFocusNode = FocusNode();

  String? _senderUserId;
  String? _recipientUserId;
  String? _currentUserRole;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());

    if (widget.product != null) {
      _product = widget.product!;
    }

    super.initState();
  }

  @override
  void dispose() {
    _barterStreamSub?.cancel();
    _barterStreamSub = null;
    _barterChatStreamSub?.cancel();
    _barterChatStreamSub = null;
    _barterProductsStream?.cancel();
    _barterProductsStream = null;
    DialogMessage.dismiss();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    setState(() {
      _closing = true;
    });
    bool shouldExit = true;
    if (_offersChanged()) {
      final result = await showDialog(
        context: context,
        builder: (dContext) {
          return Dialog(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: EdgeInsets.all(10.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Warning',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Changes were made, do you want to send your offers?',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          bgColor: Colors.red.shade400,
                          label: 'Cancel',
                          onTap: () {
                            Navigator.pop(dContext, false);
                          },
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: CustomButton(
                          bgColor: kDangerColor,
                          label: 'No',
                          onTap: () => Navigator.pop(dContext),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: CustomButton(
                          bgColor: kBackgroundColor,
                          label: 'Yes',
                          onTap: () {
                            Navigator.pop(dContext, true);
                            _onSubmitTapped();
                          },
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

      if (result != null) {
        shouldExit = result;
      } else {
        List<dynamic> _unsavedOfferedProducts = [];
        List<dynamic> _unsavedWantedProducts = [];

        origOffers.forEach((oOffer) {
          final stillExists =
              offers.any((offer) => offer.productId == oOffer.productId);
          if (!stillExists || offers.length != origOffers.length)
            _unsavedOfferedProducts.addAll(offers);
        });

        origWants.forEach((oWant) {
          final stillExists =
              wants.any((want) => want.productId == oWant.productId);
          if (!stillExists || wants.length != origWants.length)
            _unsavedWantedProducts.addAll(wants);
        });

        if (_unsavedOfferedProducts.isNotEmpty) {
          // save to local storage
          await unsaveProductsStorage.setItem(
              'offered', _unsavedOfferedProducts);
          // await unsaveProductsStorage.setItem(
          //     'offeredDateUpdated', DateTime.now());
        }

        if (_unsavedWantedProducts.isNotEmpty) {
          unsaveProductsStorage.setItem('wanted', _unsavedWantedProducts);
          // await unsaveProductsStorage.setItem(
          //     'wantedDateUpdated', DateTime.now());
        }
      }
    }

    return shouldExit;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Color(0xFFEBFBFF),
        body: ProgressHUD(
          indicatorColor: kBackgroundColor,
          backgroundColor: Colors.white,
          barrierEnabled: false,
          child: SlidingUpPanel(
            maxHeight: SizeConfig.screenHeight * 0.74,
            controller: _panelController,
            isDraggable: false,
            onPanelClosed: () {
              setState(() {
                _panelClosed = true;
              });
            },
            onPanelOpened: () {
              setState(() {
                _panelClosed = false;
              });
            },
            collapsed: _buildCollapsed(),
            panel: _buildPanel(),
            body: _buildBody(context),
          ),
        ),
      ),
    );
  }

  MultiBlocListener _buildBody(BuildContext context) {
    return MultiBlocListener(
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

              if (!_closing) {
                await DialogMessage.show(
                  context,
                  title: 'Info',
                  message: _barterRecord!.dealStatus != 'accepted'
                      ? _currentUserRole == 'recipient'
                          ? 'You have accepted this offer'
                          : 'You have submitted this offer'
                      : 'You have accepted this offer',
                  hideClose: true,
                );
              }
              await unsaveProductsStorage.clear();
            }

            if (state is BarterInitialized) {
              setState(() {
                participantItems = state.recipientProducts;
                userItems = state.senderProducts;
              });

              final unsavedOfferedProducts = await unsaveProductsStorage
                  .getItem('offered') as List<dynamic>?;
              final unsavedWantedProducts = await unsaveProductsStorage
                  .getItem('wanted') as List<dynamic>?;

              _barterStreamSub = state.barterStream.listen((barterRecord) {
                if (barterRecord == null) {
                  Navigator.pop(context);
                  return;
                }
                setState(() {
                  _barterRecord = barterRecord;
                  if (_barterId == null) {
                    print('-===== ${_barterRecord!.toJson()}');
                    _barterId = _barterRecord!.barterId;
                  }

                  _barterBloc.add(InitializeBarterChat(_barterId!));

                  if (_barterRecord!.userid1Role == 'sender') {
                    _senderUserId = _barterRecord!.userid1;
                    _recipientUserId = _barterRecord!.userid2;
                    _recipientName = _barterRecord!.userid2!;
                  } else {
                    _senderUserId = _barterRecord!.userid2;
                    _recipientUserId = _barterRecord!.userid1;
                    _recipientName = _barterRecord!.userid1!;
                  }

                  if (_senderUserId == _currentUser!.uid) {
                    _currentUserRole = 'sender';
                  } else {
                    _currentUserRole = 'recipient';
                  }

                  _recipientName = _recipientName.length > 10
                      ? _recipientName.substring(0, 7) + '...'
                      : _recipientName;
                });
              });

              _barterProductsStream = state.barterProductsStream.listen((list) {
                if (list.isNotEmpty) {
                  setState(() {
                    wants.clear();
                    offers.clear();
                    origOffers.clear();
                    origWants.clear();
                    _offeredCash = null;
                    _requestedCash = null;
                    _origOfferedCash = null;
                    _origRequestedCash = null;
                  });
                  list.forEach((bProduct) {
                    final _prod = ProductModel.fromJson(bProduct.toJson());
                    if (bProduct.productId!.contains('cash')) {
                      if (_currentUser!.uid == _senderUserId) {
                        if (_senderUserId == bProduct.userId) {
                          _origOfferedCash = bProduct.price;
                          _offeredCash = bProduct.price;
                          setState(() {
                            _offeredCashModel = bProduct;
                          });
                        } else {
                          setState(() {
                            _requestedCashModel = bProduct;
                          });
                          _requestedCash = bProduct.price;
                          _origRequestedCash = bProduct.price;
                        }
                      } else {
                        if (_recipientUserId == bProduct.userId) {
                          setState(() {
                            _requestedCashModel = bProduct;
                          });
                          _requestedCash = bProduct.price;
                          _origRequestedCash = bProduct.price;
                        } else {
                          _origOfferedCash = bProduct.price;
                          _offeredCash = bProduct.price;
                          setState(() {
                            _offeredCashModel = bProduct;
                          });
                        }
                      }
                    } else {
                      if (_currentUserRole == 'sender') {
                        if (bProduct.userId == _senderUserId) {
                          offers.add(bProduct);
                          origOffers.add(bProduct);
                        } else {
                          wants.add(bProduct);
                          origWants.add(bProduct);
                        }
                      } else {
                        if (bProduct.userId == _recipientUserId) {
                          wants.add(bProduct);
                          origWants.add(bProduct);
                        } else {
                          offers.add(bProduct);
                          origOffers.add(bProduct);
                        }
                      }
                    }
                  });

                  if (unsavedOfferedProducts != null &&
                      unsavedOfferedProducts.isNotEmpty) {
                    final list = unsavedOfferedProducts
                        .map((data) => data as BarterProductModel)
                        .toList();
                    list.forEach((prod) {
                      if (!offers
                          .any((item) => item.productId == prod.productId)) {
                        offers.add(prod);
                      }
                    });
                  }

                  if (unsavedWantedProducts != null &&
                      unsavedWantedProducts.isNotEmpty) {
                    final list = unsavedWantedProducts
                        .map((data) => data as BarterProductModel)
                        .toList();
                    list.forEach((prod) {
                      if (!wants
                          .any((item) => item.productId == prod.productId)) {
                        wants.add(prod);
                      }
                    });
                  }
                }
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
                setState(() {
                  _barterId = _currentUser!.uid +
                      _product!.userid! +
                      _product!.productid!;
                });

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
                      userid1Role: 'sender',
                      userid2Role: 'recipient',
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding:
                  EdgeInsets.fromLTRB(16.0, SizeConfig.paddingTop, 16.0, 0),
              height: kToolbarHeight + SizeConfig.paddingTop,
              color: kBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (!_panelClosed) {
                        _panelController.close();
                        return;
                      }
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
                    'Barter with $_recipientName',
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
            _panelClosed ? _buildExpandedView() : _buildMinimizedView(),
          ],
        ),
      ),
    );
  }

  Container _buildPanel() {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: BlocListener(
              bloc: _barterBloc,
              listener: (context, state) {
                if (state is BarterLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is SendMessageSuccess) {
                  _messageTextController.clear();
                }

                if (state is BarterChatInitialized) {
                  _barterChatStreamSub = state.barterChatStream.listen((list) {
                    setState(() {
                      if (list.isNotEmpty) {
                        _messages = list;
                      } else {
                        _messages.clear();
                      }
                    });
                  });
                }

                if (state is BarterError) {
                  print('BARTER ERROR ===== ${state.message}');
                }
              },
              child: Visibility(
                visible: !_panelClosed,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Barter Chat',
                                style: Style.subtitle2
                                    .copyWith(color: kBackgroundColor),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () => _panelController.close(),
                                  child: Container(
                                    child: Icon(
                                      Icons.close,
                                      size: 30.0,
                                      color: kBackgroundColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        reverse: true,
                        children: _messages.reversed
                            .map((msg) => buildChatItem(msg, _currentUser))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            color: kBackgroundColor,
            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            width: double.infinity,
            height: kToolbarHeight + 10,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    style: TextStyle(
                      color: kBackgroundColor,
                      fontSize: 18.0,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    controller: _messageTextController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      hintText: 'Enter your message here',
                    ),
                    focusNode: _chatFocusNode,
                  ),
                ),
                SizedBox(width: 10.0),
                InkWell(
                  onTap: _onChatTapped,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 1),
                          blurRadius: 2.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    child: Icon(
                      FontAwesomeIcons.paperPlane,
                      color: kBackgroundColor,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserButtons([bool removeChatBtn = false]) {
    List<Widget> buttons = [];

    if (_barterRecord!.dealStatus == 'sold') {
      buttons.add(
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: 8.0),
            child: CustomButton(
              removeMargin: true,
              label: 'Dispute',
              onTap: () {},
            ),
          ),
        ),
      );
    }

    if (_currentUser!.uid == _senderUserId) {
      // show sender buttons
      if (_barterRecord!.dealStatus != 'sold') {
        buttons.addAll([
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                enabled: _offersChanged(),
                removeMargin: true,
                label: _barterRecord!.dealStatus == 'new'
                    ? 'Submit'
                    : 'Make Offer',
                onTap: _onSubmitTapped,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                removeMargin: true,
                bgColor: Color(0xFFBB3F03),
                label: 'Withdraw',
                onTap: _onCancelTapped,
              ),
            ),
          ),
        ]);
      }
    } else {
      buttons.addAll([
        Visibility(
          visible: !['rejected', 'accepted', 'withdrawn']
              .contains(_barterRecord!.dealStatus),
          child: Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                removeMargin: true,
                label: 'Accept',
                onTap: _onSubmitTapped,
              ),
            ),
          ),
        ),
        Visibility(
          visible: ['rejected', 'accepted', 'withdrawn']
              .contains(_barterRecord!.dealStatus),
          child: Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                enabled: _offersChanged(),
                removeMargin: true,
                label: 'Make Offer',
                onTap: _onSubmitTapped,
              ),
            ),
          ),
        ),
        Visibility(
          visible: !['rejected', 'accepted', 'withdrawn']
              .contains(_barterRecord!.dealStatus),
          child: Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                enabled: _barterRecord!.dealStatus == 'submitted',
                removeMargin: true,
                bgColor: Color(0xFFBB3F03),
                label: 'Reject',
                onTap: _onCancelTapped,
              ),
            ),
          ),
        ),
      ]);
    }

    if (!removeChatBtn) {
      buttons.add(
        Expanded(
          child: CustomButton(
            label: 'Chat',
            bgColor: kBackgroundColor,
            textColor: Colors.white,
            onTap: () => _panelController.open(),
            removeMargin: true,
          ),
        ),
      );
    }

    return buttons;
  }

  Container _buildCollapsed() {
    if (_barterRecord == null) return Container();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: _buildUserButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    if (_barterRecord == null) return Container();
    return Container(
      height: SizeConfig.screenHeight * 0.78,
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarterStatus(),
            _buildBarterList(
              label: _currentUser!.uid == _senderUserId
                  ? 'You want these item(s) from $_recipientName'
                  : '$_recipientName wants these item(s) from you',
              items: [
                _requestedCash != null
                    ? Stack(
                        children: [
                          InkWell(
                              onTap: () {
                                if (_barterRecord!.dealStatus != 'sold') {
                                  _showAddCashDialog('participant');
                                }
                              },
                              child: buildCashItem(_requestedCash!)),
                          Visibility(
                            child: Positioned(
                              top: 8.0,
                              right: 14.0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _requestedCash = null;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                    color: kDangerColor,
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
                          ),
                        ],
                      )
                    : Container(),
                ...wants.map((item) {
                  return Container(
                    margin: EdgeInsets.only(right: 8.0, bottom: 5.0),
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
                        Visibility(
                          visible: _barterRecord != null &&
                              _barterRecord!.dealStatus != 'sold',
                          child: Positioned(
                            top: 5.0,
                            right: 5.0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  wants.removeWhere((product) =>
                                      product.productId == item.productId);
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
                        ),
                      ],
                    ),
                  );
                }).toList()
              ],
              addBtnTapped: _showParticipantItems,
              showAddBtn:
                  _barterRecord != null && _barterRecord!.dealStatus != 'sold',
            ),
            _buildBarterList(
              label: _currentUserRole == 'sender'
                  ? 'Your offer'
                  : 'Offers from $_recipientName',
              labelAction: Text(
                '${offers.length} Item(s) offered',
              ),
              items: [
                _offeredCash != null
                    ? Stack(
                        children: [
                          InkWell(
                              onTap: () {
                                if (_barterRecord!.dealStatus != 'sold') {
                                  _showAddCashDialog('user');
                                }
                              },
                              child: buildCashItem(_offeredCash!)),
                          Visibility(
                            visible: _barterRecord != null &&
                                _barterRecord!.dealStatus != 'sold',
                            child: Positioned(
                              top: 8.0,
                              right: 14.0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _offeredCash = null;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                    color: kDangerColor,
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
                          ),
                        ],
                      )
                    : Container(),
                ...offers.map((item) {
                  return Container(
                    margin: EdgeInsets.only(right: 8.0, bottom: 5.0),
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
                        Visibility(
                          visible: _barterRecord != null &&
                              _barterRecord!.dealStatus != 'sold',
                          child: Positioned(
                            top: 5.0,
                            right: 5.0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  offers.removeWhere((product) =>
                                      product.productId == item.productId);
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
                        ),
                      ],
                    ),
                  );
                }).toList()
              ],
              addBtnTapped: _showUserItems,
              // _showUserItems,
              showAddBtn:
                  _barterRecord != null && _barterRecord!.dealStatus != 'sold',
            ),
            _barterRecord != null && _barterRecord!.dealStatus != 'sold'
                ? Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Center(
                      child: Text(
                        'Tap the (+) icon to add items on your barter, you can select multiple items from your gallery.',
                        style: Style.bodyText1.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarterStatus() {
    if (_barterRecord == null) return Container();
    //'$_recipientName has proposed this deal'
    var message = '';

    if (_barterRecord!.dealStatus == 'accepted') {
      if (_currentUserRole == 'recipient') {
        message = 'You accepted this offer';
      } else {
        message = '$_recipientName has accepted your offer';
      }
    }

    if (_barterRecord!.dealStatus == 'rejected') {
      if (_currentUserRole == 'recipient') {
        message = 'You have rejected this offer';
      } else {
        message = '$_recipientName rejected this offer';
      }
    }

    if (_barterRecord!.dealStatus == 'new') {
      message = 'You initiated this barter';
    }

    if (_barterRecord!.dealStatus == 'submitted') {
      if (_currentUserRole == 'recipient') {
        message = '$_recipientName submitted this offer';
      } else {
        message = 'Your offer has been submitted';
      }
    }

    if (_barterRecord!.dealStatus == 'withdrawn') {
      if (_currentUserRole == 'recipient') {
        message = '$_recipientName withdrawn this offer';
      } else {
        message = 'You withdrawn this offer';
      }
    }

    if (_barterRecord!.dealStatus == 'sold') {
      if (_currentUserRole == 'recipient') {
        message = '$_recipientName has marked this barter as sold';
      } else {
        message = 'You marked this barter as sold';
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: kDangerColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Style.bodyText1.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Container _buildMinimizedView() {
    List<Widget> wantWidgets = [];
    List<Widget> offerWidgets = [];

    if (_requestedCash != null) {
      wantWidgets.add(
        InkWell(
          onTap: () {
            if (_barterRecord!.dealStatus != 'sold') {
              _showAddCashDialog('participant');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: kBackgroundColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
              image: DecorationImage(
                image: AssetImage('assets/images/cash_icon.png'),
                fit: BoxFit.cover,
                colorFilter:
                    ColorFilter.mode(kBackgroundColor, BlendMode.color),
              ),
            ),
          ),
        ),
      );
    }

    wantWidgets.addAll(wants.reversed.map((want) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: kBackgroundColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8.0),
          image: DecorationImage(
            image: want.imgUrl!.isNotEmpty
                ? NetworkImage(want.imgUrl!)
                : AssetImage('assets/images/image_placeholder.jpg')
                    as ImageProvider<Object>,
            fit: BoxFit.cover,
          ),
        ),
      );
    }).toList());

    if (_offeredCash != null) {
      offerWidgets.add(
        InkWell(
          onTap: () => _showAddCashDialog('user'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: kBackgroundColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
              image: DecorationImage(
                image: AssetImage('assets/images/cash_icon.png'),
                fit: BoxFit.cover,
                colorFilter:
                    ColorFilter.mode(kBackgroundColor, BlendMode.color),
              ),
            ),
          ),
        ),
      );
    }

    offerWidgets.addAll(
      offers.reversed.map((offer) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: kBackgroundColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8.0),
            image: DecorationImage(
              image: offer.imgUrl!.isNotEmpty
                  ? NetworkImage(offer.imgUrl!)
                  : AssetImage('assets/images/image_placeholder.jpg')
                      as ImageProvider<Object>,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      height: SizeConfig.screenHeight * 0.2,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: () => _panelController.close(),
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: SizeConfig.screenHeight * 0.1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: GridView.count(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(vertical: 2.0),
                                  mainAxisSpacing: 5.0,
                                  crossAxisCount: 1,
                                  reverse: true,
                                  children: wantWidgets,
                                ),
                              ),
                            ),
                            SizedBox(height: 5.0),
                            Text('Cash: \$ ${_requestedCash ?? '0.00'}'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 17.0),
                      child: Icon(
                        Icons.sync_alt_outlined,
                        size: 25.0,
                        color: kBackgroundColor,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: SizeConfig.screenHeight * 0.1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: GridView.count(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(vertical: 2.0),
                                  mainAxisSpacing: 5.0,
                                  crossAxisCount: 1,
                                  reverse: true,
                                  children: offerWidgets,
                                ),
                              ),
                            ),
                            SizedBox(height: 5.0),
                            Text('Cash: \$ ${_offeredCash ?? '0.00'}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: _buildUserButtons(true),
            ),
          ],
        ),
      ),
    );
  }

  String _getGoBtnText() {
    if (_barterRecord == null) {
      return '';
    }

    if (_barterRecord!.dealStatus == 'accepted') {
      if (_currentUserRole == 'recipient') {
        if (_offersChanged()) {
          return 'Make Offer';
          // return 'Counter Offer';
        } else {
          return 'Mark as Sold';
        }
      } else {
        return 'Make Offer';
        // return 'Change Offer';
      }
    }

    if (_barterRecord!.dealStatus == 'rejected') {
      return 'Make Offer';
      // if (widget.fromOtherUser) {
      //   return 'Counter Offer';
      // } else {
      //   return ('Make Offer');
      // }
    }

    if (_barterRecord!.dealStatus == 'new') {
      return 'Submit';
    }

    if (_barterRecord!.dealStatus == 'submitted') {
      if (_currentUserRole == 'recipient') {
        if (_offersChanged()) {
          return 'Make Offer';
        } else {
          return 'Accept';
        }
      } else {
        return 'Make Offer';
        // return 'Change Offer';
      }
    }

    if (_barterRecord!.dealStatus == 'withdrawn') {
      return 'Make Offer';
    }

    return 'Leave a Review';
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

  _onSubmitTapped() async {
    if (_barterRecord != null && _barterRecord!.dealStatus == 'sold') {
      return;
    }

    if (!_closing) {
      String message = '';

      if (_barterRecord!.dealStatus == 'accepted') {
        if (_currentUserRole == 'recipient') {
          if (_offersChanged()) {
            message =
                'You are about to submit a counter offer\n\nDo you want to continue?';
          } else {
            message =
                'You are about to mark this item as sold.\n\nThis closes the transaction and cannot be reversed.\n\nIf there are any disputes after the transaction is closed, there is a \'Dispute\' button at the barter screen.\n\n\nDo you want to continue?';
          }
        } else {
          message = 'Do you want to change your offer?';
        }
      }

      if (_barterRecord!.dealStatus == 'rejected' ||
          _barterRecord!.dealStatus == 'withdrawn') {
        if (_currentUserRole == 'sender') {
          message =
              'You are about to make a new offer\n\nDo you want to continue?';
        } else {
          message =
              'You are about to counter offer\n\nDo you want to continue?';
        }
      }

      if (_barterRecord!.dealStatus == 'new') {
        message =
            'You are about to submit this offer\n\nDo you want to continue?';
      }

      print('CURRENT USER ROLE: $_currentUserRole');

      if (_barterRecord!.dealStatus == 'submitted') {
        if (_currentUserRole == 'recipient') {
          message = 'You are about to accept this offer';
          if (_offersChanged()) {
            message += ' and offer a counter proposal';
          }
          message += '\n\nDp you want to continue?';
        } else {
          message =
              'You are about to change your offer\n\nDo you want to continue?';
        }
      }

      final shouldContinue = await DialogMessage.show(
        context,
        message: message,
        title: 'Warning',
        buttonText: 'Yes',
        secondButtonText: 'No',
        result1: true,
        result2: false,
      );

      if (shouldContinue == null || !shouldContinue) return;
    }

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
        _barterBloc.add(
          DeleteCashOffer(
            barterId: _barterRecord!.barterId!,
            productId: _offeredCashModel!.productId!,
          ),
        );
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
        _barterBloc.add(
          DeleteCashOffer(
            barterId: _barterRecord!.barterId!,
            productId: _requestedCashModel!.productId!,
          ),
        );
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
        if (_currentUserRole == 'recipient') {
          if (_offersChanged()) {
            print('countering offer');
            _barterBloc.add(CounterOffer(_barterId!, wants[0]));
          } else {
            _barterBloc
                .add(UpdateBarterStatus(_barterRecord!.barterId!, 'accepted'));
          }
        } else
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        break;
      case 'accepted':
        if (_currentUserRole == 'recipient') {
          if (_offersChanged()) {
            print('countering offer');
            _barterBloc.add(CounterOffer(_barterId!, wants[0]));
          } else {
            _barterBloc
                .add(UpdateBarterStatus(_barterRecord!.barterId!, 'sold'));
          }
        } else
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        break;
      case 'withdrawn':
      case 'rejected':
        if (_currentUserRole == 'sender') {
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        } else {
          print('countering offer');
          _barterBloc.add(CounterOffer(_barterId!, wants[0]));
        }
        break;
      default:
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
    }
  }

  _onCancelTapped() async {
    final shouldContinue = await DialogMessage.show(
      context,
      message: _currentUserRole == 'recipient'
          ? 'You are about to reject this offer, do you want to continue?'
          : 'You are about to withdraw this barter, do you want to continue?',
      title: 'Warning',
      buttonText: 'Yes',
      secondButtonText: 'No',
      result1: true,
      result2: false,
    );

    if (!shouldContinue) return;

    switch (_barterRecord!.dealStatus) {
      case 'submitted':
        if (_currentUserRole == 'recipient')
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'rejected'));
        else
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'withdrawn'));
        break;
      case 'accepted':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'withdrawn'));
        break;
      case 'new':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'withdrawn'));
        break;
      default:
    }
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
                    child: buildAddItemBtn(
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
        return StatefulBuilder(
          builder: (context, setState) {
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
                    label: _currentUserRole == 'recipient'
                        ? 'Select from your store'
                        : 'Select item(s) from $_recipientName',
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
                                width: SizeConfig.screenWidth * 0.40,
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
                                width: SizeConfig.screenWidth * 0.40,
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
                            // if (_currentUserRole == 'sender')
                            //   _add_offeredCashItems(selectedItems
                            //       .map((item) =>
                            //           BarterProductModel.fromProductModel(item))
                            //       .toList());
                            // else

                            Navigator.pop(context);
                          },
                          removeMargin: true,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: CustomButton(
                          label: _requestedCash != null
                              ? 'Edit ${_currentUserRole == 'sender' ? 'Requested' : 'Offered'} Cash'
                              : '${_currentUserRole == 'sender' ? 'Request' : 'Offer'} Cash',
                          bgColor: Color(0xFFBB3F03),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCashDialog(_currentUserRole == 'recipient'
                                ? 'participant'
                                : 'user');
                          },
                          removeMargin: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _showAddCashDialog(String from) async {
    if (from == 'participant') {
      if (_currentUserRole == 'recipient') {
        amounTextController.text =
            _offeredCash != null ? _offeredCash.toString() : '';
      } else {
        amounTextController.text =
            _requestedCash != null ? _requestedCash.toString() : '';
      }
    } else {
      if (_currentUserRole == 'recipient') {
        amounTextController.text =
            _requestedCash != null ? _requestedCash.toString() : '';
      } else {
        amounTextController.text =
            _offeredCash != null ? _offeredCash.toString() : '';
      }
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

    if (amount != null) {
      amount = amount as num;

      setState(() {
        if (from == 'participant') {
          if (_currentUserRole == 'recipient') {
            _offeredCash = amount;
          } else {
            _requestedCash = amount;
          }
        } else {
          if (_currentUserRole == 'recipient') {
            _requestedCash = amount;
          } else {
            _offeredCash = amount;
          }
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
                    label: _currentUserRole == 'sender'
                        ? 'Select from your store'
                        : 'Request items from $_recipientName',
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
                              width: SizeConfig.screenWidth * 0.40,
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
                              width: SizeConfig.screenWidth * 0.40,
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
                            // if (_currentUserRole == 'recipient')
                            //   _add_offeredCashItems(selectedItems
                            //       .map((item) =>
                            //           BarterProductModel.fromProductModel(item))
                            //       .toList());
                            // else
                            //   _addWantedItems(selectedItems
                            //       .map((item) =>
                            //           BarterProductModel.fromProductModel(item))
                            //       .toList());
                            Navigator.pop(context);
                          },
                          removeMargin: true,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: CustomButton(
                          label: _offeredCash != null
                              ? 'Edit ${_currentUserRole == 'recipient' ? 'Requested' : 'Offered'} Cash'
                              : '${_currentUserRole == 'recipient' ? 'Request' : 'Offer'} Cash',
                          bgColor: Color(0xFFBB3F03),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCashDialog(_currentUserRole == 'recipient'
                                ? 'participant'
                                : 'user');
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

  _onChatTapped() {
    if (_messageTextController.text.trim().isEmpty) return;

    _barterBloc.add(
      SendMessage(
        ChatMessageModel(
          barterId: _barterId,
          message: _messageTextController.text.trim(),
        ),
      ),
    );

    if (_chatFocusNode.hasFocus) _chatFocusNode.unfocus();
  }
}
