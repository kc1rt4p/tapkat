import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  String _participantName = '';
  List<ProductModel> participantItems = [];
  List<ProductModel> userItems = [];
  User? _currentUser;
  BarterRecordModel? _barterRecord;
  StreamSubscription<BarterRecordModel>? _barterStreamSub;
  StreamSubscription<List<BarterProductModel>>? _barterProductsStream;
  String? _barterId;
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
            maxHeight: SizeConfig.screenHeight * 0.75,
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
                      ? widget.fromOtherUser
                          ? 'You have accepted this offer'
                          : 'You have submitted this offer'
                      : 'You have accepted this offer',
                  hideClose: true,
                );
              }
            }

            if (state is BarterInitialized) {
              setState(() {
                participantItems = state.user2Products;
                userItems = state.userProducts;
              });

              _barterProductsStream = state.barterProductsStream.listen((list) {
                if (list.isNotEmpty) {
                  wants.clear();
                  offers.clear();
                  origOffers.clear();
                  origWants.clear();
                  list.forEach((bProduct) {
                    final _prod = ProductModel.fromJson(bProduct.toJson());
                    if (bProduct.productId!.contains('cash')) {
                      if (!widget.fromOtherUser) {
                        if (bProduct.userId == _currentUser!.uid) {
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
                        if (bProduct.userId == _currentUser!.uid) {
                          _requestedCash = bProduct.price;
                          _origRequestedCash = bProduct.price;
                          _requestedCashModel = bProduct;
                        } else {
                          _offeredCashModel = bProduct;
                          _origOfferedCash = bProduct.price;
                          _offeredCash = bProduct.price;
                        }
                      }
                    } else {
                      if (_prod.userid == _currentUser!.uid) {
                        if (widget.fromOtherUser) {
                          wants.add(bProduct);
                          origWants.add(bProduct);
                        } else {
                          offers.add(bProduct);
                          origOffers.add(bProduct);
                        }
                      } else {
                        if (widget.fromOtherUser) {
                          offers.add(bProduct);
                          origOffers.add(bProduct);
                        } else {
                          wants.add(bProduct);
                          origWants.add(bProduct);
                        }
                      }
                    }
                  });
                }
              });

              _barterStreamSub = state.barterStream.listen((barterRecord) {
                setState(() {
                  _barterRecord = barterRecord;
                  if (_barterId == null) {
                    _barterId = _barterRecord!.barterId;
                  }

                  _barterBloc.add(InitializeBarterChat(_barterId!));

                  if (widget.fromOtherUser) {
                    _participantName = _barterRecord!.userid1!;
                  } else {
                    _participantName = _barterRecord!.userid2!;
                  }
                  _participantName = _participantName.length > 10
                      ? _participantName.substring(0, 7) + '...'
                      : _participantName;
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
                    if (list.isNotEmpty) {
                      setState(() {
                        _messages = list;
                      });
                    }
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
                            .map((msg) => _buildChatItem(msg))
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
            children: [
              Visibility(
                visible: _barterRecord != null,
                child: Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 10.0),
                    child: CustomButton(
                      label: _getGoBtnText(),
                      textColor: Colors.white,
                      onTap: _onSubmitTapped,
                      removeMargin: true,
                      enabled: _offersChanged() ||
                          (_barterRecord!.dealStatus == 'submitted' &&
                              widget.fromOtherUser) ||
                          (_barterRecord!.dealStatus == 'accepted' &&
                              widget.fromOtherUser) ||
                          _barterRecord!.dealStatus == 'sold',
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: (_barterRecord!.dealStatus != 'sold' &&
                        _barterRecord!.dealStatus != 'withdrawn' &&
                        _barterRecord!.dealStatus != 'rejected') &&
                    (_barterRecord!.dealStatus != 'accepted' &&
                        !widget.fromOtherUser),
                child: Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 10.0),
                    child: CustomButton(
                      label: widget.fromOtherUser ? 'Reject' : 'Withdraw',
                      bgColor: Color(0xFFBB3F03),
                      textColor: Colors.white,
                      onTap: _onCancelTapped,
                      removeMargin: true,
                      enabled: _barterRecord!.dealStatus != 'new',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CustomButton(
                  label: 'Chat',
                  bgColor: kBackgroundColor,
                  textColor: Colors.white,
                  onTap: () => _panelController.open(),
                  removeMargin: true,
                ),
              ),
              Visibility(
                visible: _barterRecord!.dealStatus == 'sold',
                child: Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 10.0),
                    child: CustomButton(
                      label: 'Dispute',
                      bgColor: kDangerColor,
                      textColor: Colors.white,
                      onTap: () {},
                      removeMargin: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Container(
      height: SizeConfig.screenHeight * 0.79,
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarterStatus(),
            _barterRecord != null && _barterRecord!.dealStatus != 'sold'
                ? Container(
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Tap the (+) icon to add items on your barter, you can select multiple items from your gallery.',
                      style: Style.bodyText1.copyWith(fontSize: 12),
                    ),
                  )
                : Container(),
            _buildBarterList(
              label: !widget.fromOtherUser
                  ? 'You want these item(s) from $_participantName'
                  : '$_participantName wants these item(s) from you',
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
                              child: _buildCashItem(_requestedCash!)),
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
              label: !widget.fromOtherUser
                  ? 'Your offer'
                  : 'Offers from $_participantName',
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
                              child: _buildCashItem(_offeredCash!)),
                          Visibility(
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
              showAddBtn:
                  _barterRecord != null && _barterRecord!.dealStatus != 'sold',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarterStatus() {
    if (_barterRecord == null) return Container();
    //'$_participantName has proposed this deal'
    var message = '';

    switch (_barterRecord!.dealStatus) {
      case 'new':
        message = 'You initiated this barter';
        break;
      case 'withdrawn':
        if (widget.fromOtherUser) {
          message = '$_participantName has withdrawn this deal';
        } else
          message = 'You have withdrawn this barter';
        break;
      case 'rejected':
        if (widget.fromOtherUser) {
          message = '$_participantName has rejected this deal';
        } else
          message = 'Your offer has been rejected';
        break;
      case 'submitted':
        if (widget.fromOtherUser) {
          message = '$_participantName has proposed this deal';
        } else
          message = 'Your offer has been submitted';
        break;
      case 'accepted':
        if (widget.fromOtherUser) {
          message = 'You accepted this offer';
        } else
          message = 'Your offer has been accepted';
        break;
      case 'sold':
        if (widget.fromOtherUser) {
          message =
              'You marked this barter as sold, you may now leave a review';
        } else
          message =
              '$_participantName has marked this barter as sold, you may now leave a review';
        break;
      default:
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
                                  shrinkWrap: true,
                                  crossAxisCount: 1,
                                  children: [
                                    Visibility(
                                      visible: _requestedCash != null,
                                      child: InkWell(
                                        onTap: () {
                                          if (_barterRecord!.dealStatus !=
                                              'sold') {
                                            _showAddCashDialog('participant');
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: kBackgroundColor,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/cash_icon.png'),
                                              fit: BoxFit.cover,
                                              colorFilter: ColorFilter.mode(
                                                  kBackgroundColor,
                                                  BlendMode.color),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...wants.map((want) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: kBackgroundColor,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          image: DecorationImage(
                                            image: want.imgUrl!.isNotEmpty
                                                ? NetworkImage(want.imgUrl!)
                                                : AssetImage(
                                                        'assets/images/image_placeholder.jpg')
                                                    as ImageProvider<Object>,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
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
                                  shrinkWrap: true,
                                  crossAxisCount: 1,
                                  children: [
                                    Visibility(
                                      visible: _offeredCash != null,
                                      child: InkWell(
                                        onTap: () => _showAddCashDialog('user'),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: kBackgroundColor,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/images/cash_icon.png'),
                                              fit: BoxFit.cover,
                                              colorFilter: ColorFilter.mode(
                                                  kBackgroundColor,
                                                  BlendMode.color),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...offers.map((offer) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: kBackgroundColor,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          image: DecorationImage(
                                            image: offer.imgUrl!.isNotEmpty
                                                ? NetworkImage(offer.imgUrl!)
                                                : AssetImage(
                                                        'assets/images/image_placeholder.jpg')
                                                    as ImageProvider<Object>,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
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
              children: [
                Visibility(
                  visible: _barterRecord != null,
                  child: Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 10.0),
                      child: CustomButton(
                        label: _getGoBtnText(),
                        textColor: Colors.white,
                        onTap: _onSubmitTapped,
                        removeMargin: true,
                        enabled: _offersChanged() ||
                            (_barterRecord!.dealStatus == 'submitted' &&
                                widget.fromOtherUser) ||
                            (_barterRecord!.dealStatus == 'accepted' &&
                                widget.fromOtherUser) ||
                            _barterRecord!.dealStatus == 'sold',
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: _barterRecord!.dealStatus != 'sold' &&
                      _barterRecord!.dealStatus != 'withdrawn' &&
                      _barterRecord!.dealStatus != 'rejected',
                  child: Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 10.0),
                      child: CustomButton(
                        label: widget.fromOtherUser ? 'Reject' : 'Withdraw',
                        bgColor: Color(0xFFBB3F03),
                        textColor: Colors.white,
                        onTap: _onCancelTapped,
                        removeMargin: true,
                        enabled: _barterRecord!.dealStatus != 'new',
                      ),
                    ),
                  ),
                ),
              ],
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
    switch (_barterRecord!.dealStatus) {
      case 'new':
      case 'withdrawn':
        return 'Make Offer';
      case 'submitted':
      case 'rejected':
        return widget.fromOtherUser ? 'Accept' : 'Make Offer';
      case 'accepted':
        return widget.fromOtherUser ? 'Mark as Sold' : 'Make Offer';
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

  _onSubmitTapped() async {
    if (_barterRecord != null && _barterRecord!.dealStatus == 'sold') {
      return;
    }

    if (!_closing) {
      final shouldContinue = await DialogMessage.show(
        context,
        message: _barterRecord!.dealStatus != 'accepted'
            ? widget.fromOtherUser
                ? 'You are about to accept this offer\nDo you want to continue?'
                : 'You are about to submit this barter\nDo you want to continue?'
            : 'You are about to mark this item as sold.\nThis closes the transaction and cannot be reversed.\nIf there are any disputes after the transaction is closed, there is \'Dispute\' button at the barter screen.\nDo you want to continue?',
        title: 'Warning',
        buttonText: 'Yes',
        secondButtonText: 'No',
        result1: true,
        result2: false,
      );

      if (!shouldContinue) return;
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
        if (widget.fromOtherUser)
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'accepted'));
        else
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        break;
      case 'accepted':
        if (widget.fromOtherUser)
          _barterBloc.add(UpdateBarterStatus(_barterRecord!.barterId!, 'sold'));
        else
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        break;
      default:
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
    }
  }

  _onCancelTapped() async {
    final shouldContinue = await DialogMessage.show(
      context,
      message: widget.fromOtherUser
          ? 'You are about to reject this offer, do you want to continue?'
          : 'You are about to withdraw this barter, do you want to continue?',
      title: 'Warning',
      buttonText: 'Yes',
      secondButtonText: 'No',
      result1: true,
      result2: false,
    );

    print('should continue: $shouldContinue');

    if (!shouldContinue) return;

    switch (_barterRecord!.dealStatus) {
      case 'submitted':
        if (widget.fromOtherUser)
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
          },
        );
      },
    );
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
        height: SizeConfig.screenHeight * 0.235,
        width: SizeConfig.screenWidth * 0.40,
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
      padding: const EdgeInsets.only(
        top: 2,
        bottom: 2,
        right: 16.0,
      ),
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
        height: SizeConfig.screenHeight * 0.24,
        width: SizeConfig.screenWidth * 0.44,
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
                      style: TextStyle(
                        fontSize: SizeConfig.textScaleFactor * 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Text(
                      amount.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: SizeConfig.textScaleFactor * 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Container _buildChatItem(ChatMessageModel msg) {
    return Container(
      margin: EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: msg.userId != _currentUser!.uid
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: msg.userId != _currentUser!.uid
                  ? kBackgroundColor
                  : Color(0xFFBB3F03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
                bottomLeft: msg.userId == _currentUser!.uid
                    ? Radius.circular(10.0)
                    : Radius.zero,
                bottomRight: msg.userId != _currentUser!.uid
                    ? Radius.circular(10.0)
                    : Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: msg.userId != _currentUser!.uid
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  msg.userId == _currentUser!.uid &&
                          _currentUser!.uid.isNotEmpty
                      ? 'You'
                      : msg.userName != null && msg.userName!.isNotEmpty
                          ? msg.userName!
                          : 'Anonymous',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12.0,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  msg.message ?? '',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeago.format(msg.dateCreated ?? DateTime.now()),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }
}
