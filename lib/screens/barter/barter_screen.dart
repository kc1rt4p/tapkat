import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as INTL;
import 'package:localstorage/localstorage.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/barter_repository.dart';
import 'package:tapkat/screens/barter/widgets/add_item_btn.dart';
import 'package:tapkat/screens/barter/widgets/cash_item.dart';
import 'package:tapkat/screens/barter/widgets/chat_item.dart';
import 'package:tapkat/screens/barter/widgets/user_items.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

import '../product/product_details_screen.dart';
import 'bloc/barter_bloc.dart';

class BarterScreen extends StatefulWidget {
  final bool existing;
  final ProductModel? product;
  final ProductModel? initialOffer;
  final BarterRecordModel? barterRecord;
  final bool showChatFirst;
  final bool buying;

  const BarterScreen({
    Key? key,
    this.product,
    this.barterRecord,
    this.showChatFirst = false,
    this.initialOffer,
    this.existing = false,
    this.buying = false,
  }) : super(key: key);

  @override
  _BarterScreenState createState() => _BarterScreenState();
}

class _BarterScreenState extends State<BarterScreen> {
  final oCcy = new INTL.NumberFormat("#,##0.00", "en_US");
  late LocalStorage unsaveProductsStorage;
  ProductModel? _product;
  num? initialCashOffer;

  final _barterRepo = BarterRepository();

  final _authBloc = AuthBloc();
  late BarterBloc _barterBloc;

  ProductModel? _initialOffer;

  List<BarterProductModel> origCurrentUserOffers = [];
  List<BarterProductModel> currentUserOffers = [];
  List<BarterProductModel> origRemoteUserOffers = [];
  List<BarterProductModel> remoteUserOffers = [];

  List<ProductModel> remoteUserItems = [];
  List<ProductModel> currentUserItems = [];

  String _recipientName = '';
  String? _barterId;

  User? _currentUser;
  BarterRecordModel? _barterRecord;
  StreamSubscription<BarterRecordModel?>? _barterStreamSub;
  StreamSubscription<List<BarterProductModel>>? _barterProductsStream;
  num? _origRemoteUserOfferedCash;
  num? _remoteUserOfferedCash;
  num? _origCurrentUserOfferedCash;
  num? _currentUserOfferedCash;
  BarterProductModel? _currentUserOfferedCashModel;
  BarterProductModel? _remoteUserOfferedCashModel;

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
  UserModel? _currentUserModel;

  BarterProductModel? _productToReview;

  UserReviewModel? _userReview;

  List<SelectedMedia> _selectedMedia = [];

  bool _existing = false;

  bool _loading = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool chatOnly = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    application.currentScreen = 'Barter Screen';
    _authBloc.add(GetCurrentuser());
    _barterBloc = BlocProvider.of<BarterBloc>(context);

    if (widget.product != null) {
      _product = widget.product!;
    }
    if (widget.barterRecord != null) {
      unsaveProductsStorage =
          new LocalStorage('${widget.barterRecord!.barterId}.json');
    } else {
      unsaveProductsStorage = new LocalStorage(
          '${application.currentUser!.uid + _product!.userid! + _product!.productid!}.json');
    }

    if (widget.buying) {
      initialCashOffer = widget.product!.price;
    }

    _initialOffer = widget.initialOffer;

    super.initState();
    _existing = widget.existing;
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
    // if (_barterRecord!.dealStatus == 'new' &&
    //     (currentUserOffers.isEmpty && _currentUserOfferedCash == null)) {
    //   // unsaveProductsStorage.clear();
    //   // _barterBloc.add(DeleteBarter(_barterId!));
    //   return false;
    // }
    if (_loading) return false;

    if (_barterRecord!.dealStatus!.toLowerCase() == 'completed') return true;

    if (((_remoteUserOfferedCash == null ||
                (_remoteUserOfferedCash != null &&
                    _remoteUserOfferedCash! < 1)) &&
            remoteUserOffers.isEmpty) ||
        (_currentUserOfferedCash == null ||
                (_currentUserOfferedCash != null &&
                    _currentUserOfferedCash! < 1)) &&
            currentUserOffers.isEmpty) {
      return true;
    }

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
                          onTap: () => Navigator.pop(dContext, null),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: CustomButton(
                          bgColor: kBackgroundColor,
                          label: 'Yes',
                          onTap: () {
                            Navigator.pop(dContext, true);
                            _onSubmitTapped(false);
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

        await unsaveProductsStorage.clear();
      } else if (result == null &&
          ['new', 'rejected', 'withdrawn']
              .contains(_barterRecord!.dealStatus)) {
        List<dynamic> _unsavedOfferedProducts = [];
        List<dynamic> _unsavedWantedProducts = [];

        if (currentUserOffers.isNotEmpty) {
          currentUserOffers.forEach((offer) {
            if (!origCurrentUserOffers
                .any((oOffer) => oOffer.productId == offer.productId)) {
              _unsavedOfferedProducts.add(offer.toJson());
            }
          });
        }

        if (remoteUserOffers.isNotEmpty) {
          remoteUserOffers.forEach((offer) {
            if (!origRemoteUserOffers
                .any((oOffer) => oOffer.productId == offer.productId)) {
              _unsavedWantedProducts.add(offer.toJson());
            }
          });
        }

        // origCurrentUserOffers.forEach((oOffer) {
        //   final stillExists = currentUserOffers
        //       .any((offer) => offer.productId == oOffer.productId);
        //   if (!stillExists ||
        //       currentUserOffers.length != origCurrentUserOffers.length ||
        //       (origCurrentUserOffers.isEmpty && currentUserOffers.isNotEmpty))
        //     _unsavedOfferedProducts.addAll(currentUserOffers);
        // });

        // origRemoteUserOffers.forEach((oWant) {
        //   final stillExists =
        //       remoteUserOffers.any((want) => want.productId == oWant.productId);
        //   if (!stillExists ||
        //       remoteUserOffers.length != origRemoteUserOffers.length ||
        //       (origRemoteUserOffers.isEmpty && remoteUserOffers.isNotEmpty))
        //     _unsavedWantedProducts.addAll(remoteUserOffers);
        // });

        // save to local storage
        await unsaveProductsStorage.clear();
        await unsaveProductsStorage.setItem('offered', _unsavedOfferedProducts);
        await unsaveProductsStorage.setItem(
            'offeredDateUpdated', DateTime.now().toString());

        await unsaveProductsStorage.setItem('wanted', _unsavedWantedProducts);
        await unsaveProductsStorage.setItem(
            'wantedDateUpdated', DateTime.now().toString());

        if (_currentUserOfferedCash != null ||
            (_origCurrentUserOfferedCash != null &&
                _origCurrentUserOfferedCash != _currentUserOfferedCash)) {
          await unsaveProductsStorage.setItem(
              'offeredCash', _currentUserOfferedCash);
        } else {
          await unsaveProductsStorage.deleteItem('offeredCash');
        }

        if (_remoteUserOfferedCash != null && _remoteUserOfferedCash! > 0 ||
            (_origRemoteUserOfferedCash != null &&
                _origRemoteUserOfferedCash != _remoteUserOfferedCash)) {
          await unsaveProductsStorage.setItem(
              'wantedCash', _remoteUserOfferedCash);
        } else {
          await unsaveProductsStorage.deleteItem('wantedCash');
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
      child: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Color(0xFFEBFBFF),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: SizeConfig.screenHeight,
                  child: SlidingUpPanel(
                    maxHeight: SizeConfig.screenHeight * 0.7,
                    minHeight: kToolbarHeight,
                    controller: _panelController,
                    isDraggable: false,
                    onPanelClosed: () {
                      setState(() {
                        _panelClosed = true;
                      });
                      application.chatOpened = false;
                    },
                    onPanelOpened: () {
                      setState(() {
                        _panelClosed = false;
                      });
                      application.chatOpened = true;
                    },
                    collapsed: _buildCollapsed(),
                    panel: _buildPanel(),
                    body: _buildBody(context),
                  ),
                ),
              ],
            ),
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
              _loading = true;
              ProgressHUD.of(context)!.show();
            } else {
              _loading = false;
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is GetUserReviewSuccess) {
              if (state.review != null) {
                print(state.review!.toJson());
                setState(() {
                  _userReview = state.review;
                });
              }
            }

            if (state is GetProductReviewSuccess) {
              if (_productToReview != null)
                _onRateProduct(state.review, _productToReview!);
            }

            if (state is AddUserReviewSuccess) {
              DialogMessage.show(context,
                  message: 'Your User Review has been submitted');
              if (_barterRecord!.dealStatus == 'completed') {
                _barterBloc.add(GetUserReview(
                    _currentUserModel!.userid == _senderUserId
                        ? _recipientUserId!
                        : _senderUserId!,
                    _currentUserModel!.userid!));
              }
            }

            if (state is RateProductSuccess) {
              DialogMessage.show(context,
                  message: 'Your Product Review has been submitted');
            }

            if (state is UpdateUserReviewSuccess) {
              DialogMessage.show(context,
                  message: 'Your User Review has been updated');

              if (_barterRecord!.dealStatus == 'completed') {
                _barterBloc.add(GetUserReview(
                    _currentUserModel!.userid == _senderUserId
                        ? _recipientUserId!
                        : _senderUserId!,
                    _currentUserModel!.userid!));
              }
            }

            if (state is AddRatingSuccess) {
              DialogMessage.show(context,
                  message: 'Your Product Review has been submitted');
            }

            if (state is UpdateProductRatingSuccess) {
              DialogMessage.show(context,
                  message: 'Your Product Review has been updated');
            }

            if (state is UpdateBarterProductsSuccess ||
                state is DeleteBarterProductsSuccess ||
                state is AddCashOfferSuccess) {
              unsaveProductsStorage.clear();
              setState(() {
                origCurrentUserOffers = List.from(currentUserOffers);
                origRemoteUserOffers = List.from(remoteUserOffers);
                _origCurrentUserOfferedCash = _currentUserOfferedCash;
                _origRemoteUserOfferedCash = _remoteUserOfferedCash;
              });

              // unsaveProductsStorage.ready
              // // await unsaveProductsStorage.clear();
            }

            if (state is UpdateBarterStatusSuccess) {
              String message = '';

              switch (_barterRecord!.dealStatus) {
                case 'accepted':
                  message = 'You have accepted this offer';
                  break;
                case 'revoked':
                  message = 'You have revoked acceptance for this offer';
                  break;
                case 'completed':
                  message = 'You marked this barter as completed';
                  break;
                case 'withdrawn':
                  message = 'You have withdrawn your offer';
                  break;
                case 'rejected':
                  message = 'You have rejected the offer';
                  break;
                default:
                  message = 'You have submitted this offer';
              }

              if (!_closing) {
                await DialogMessage.show(
                  context,
                  title: 'Info',
                  message: message,
                  hideClose: true,
                );
              }
            }

            if (state is BarterInitialized) {
              setState(() {
                remoteUserItems = state.remoteUserProducts;
                print(
                    'x0000x remote user items count: ${remoteUserItems.length}');
                currentUserItems = state.currentUserProducts;
                chatOnly = state.chatOnly;
              });

              remoteUserItems
                  .forEach((element) => print('X==> ${element.toJson()}'));

              _barterStreamSub = state.barterStream.listen((barterRecord) {
                if ((barterRecord == null && !widget.existing) ||
                    (barterRecord != null &&
                        barterRecord.deletedFor != null &&
                        barterRecord.deletedFor!
                            .contains(application.currentUser!.uid))) {
                  Navigator.pop(context);
                  return;
                } else {
                  setState(() {
                    _barterRecord = barterRecord;

                    print('X=======>       ${barterRecord!.toJson()}');
                    _barterId = _barterRecord!.barterId;

                    unsaveProductsStorage = new LocalStorage('$_barterId.json');

                    _barterBloc.add(InitializeBarterChat(_barterId!));

                    if (_barterRecord!.userid1Role == 'sender') {
                      _senderUserId = _barterRecord!.userid1;
                      _recipientUserId = _barterRecord!.userid2;
                    } else {
                      _senderUserId = _barterRecord!.userid2;
                      _recipientUserId = _barterRecord!.userid1;
                    }

                    if (application.currentUser!.uid ==
                        _barterRecord!.userid1) {
                      _currentUserRole = _barterRecord!.userid1Role;
                      _recipientName = _barterRecord!.userid2Name!;
                    } else {
                      _currentUserRole = _barterRecord!.userid2Role;
                      _recipientName = _barterRecord!.userid1Name!;
                    }

                    if (_barterRecord!.dealStatus == 'completed') {
                      _barterBloc.add(GetUserReview(
                          _currentUserModel!.userid == _senderUserId
                              ? _recipientUserId!
                              : _senderUserId!,
                          _currentUserModel!.userid!));
                    }

                    _recipientName = _recipientName.length > 12
                        ? _recipientName.substring(0, 7) + '...'
                        : _recipientName;
                  });

                  if (!widget.existing &&
                      state.existing &&
                      widget.barterRecord == null) {
                    DialogMessage.show(
                      context,
                      message:
                          'An existing pending barter deal was found for these products.',
                    );
                  }
                }
              });

              _barterProductsStream =
                  state.barterProductsStream.listen((list) async {
                if (list.isNotEmpty) {
                  setState(() {
                    remoteUserOffers.clear();
                    currentUserOffers.clear();
                    origCurrentUserOffers.clear();
                    origRemoteUserOffers.clear();
                    _currentUserOfferedCash = null;
                    _remoteUserOfferedCash = null;
                    _origCurrentUserOfferedCash = null;
                    _origRemoteUserOfferedCash = null;
                  });

                  list.forEach((bProduct) {
                    if (bProduct.productId!.contains('cash')) {
                      print(bProduct.toJson());
                      if (bProduct.userId == _currentUser!.uid) {
                        setState(() {
                          _currentUserOfferedCashModel = bProduct;
                        });
                        _origCurrentUserOfferedCash = bProduct.price;
                        _currentUserOfferedCash = bProduct.price;
                      } else {
                        setState(() {
                          _remoteUserOfferedCashModel = bProduct;
                        });
                        _remoteUserOfferedCash = bProduct.price;
                        _origRemoteUserOfferedCash = bProduct.price;
                      }
                    } else {
                      if (bProduct.userId == _currentUser!.uid) {
                        origCurrentUserOffers.add(bProduct);
                        if (!currentUserOffers.any((cOffer) =>
                            cOffer.productId == bProduct.productId)) {
                          currentUserOffers.add(bProduct);
                        }
                      } else {
                        origRemoteUserOffers.add(bProduct);
                        if (!remoteUserOffers.any((rOffer) =>
                            rOffer.productId == bProduct.productId)) {
                          remoteUserOffers.add(bProduct);
                        }
                      }
                    }
                  });

                  _sortProducts();

                  if (_initialOffer != null &&
                      _barterRecord!.dealStatus == 'new') {
                    if (!currentUserOffers.contains(
                        (BarterProductModel offer) =>
                            offer.productId == _initialOffer!.productid)) {
                      print('INITIAL OFFER ===== ${_initialOffer!.toJson()}');

                      var thumbnail = '';

                      if (_initialOffer!.mediaPrimary != null &&
                          _initialOffer!.mediaPrimary!.url_t != null) {
                        thumbnail = _initialOffer!.mediaPrimary!.url_t!;
                      }

                      if (thumbnail.isEmpty &&
                          _initialOffer!.media != null &&
                          _initialOffer!.media!.isNotEmpty) {
                        thumbnail = _initialOffer!.media!.first.url_t ?? '';
                      }

                      setState(() {
                        currentUserOffers.add(
                          BarterProductModel(
                            productId: _initialOffer!.productid,
                            userId: _initialOffer!.userid,
                            productName: _initialOffer!.productname,
                            imgUrl: thumbnail,
                            price: _initialOffer!.price,
                          ),
                        );
                      });
                    }

                    _initialOffer = null;
                  }

                  final unsavedOfferedProducts = await unsaveProductsStorage
                      .getItem('offered') as List<dynamic>?;
                  final unsavedWantedProducts = await unsaveProductsStorage
                      .getItem('wanted') as List<dynamic>?;

                  final unsavedOfferedCash = await unsaveProductsStorage
                      .getItem('offeredCash') as num?;

                  final unsavedWantedCash =
                      await unsaveProductsStorage.getItem('wantedCash') as num?;

                  if (unsavedOfferedProducts != null) {
                    print(
                        'unsavedOfferedProducts:: ${unsavedOfferedProducts.length}');
                  }

                  if (unsavedWantedProducts != null) {
                    print(
                        'unsavedOfferedProducts:: ${unsavedWantedProducts.length}');
                  }

                  print(
                      '0----> barter id: ${_barterId} | buying: ${widget.buying} | initialCashOffer: $initialCashOffer | existing: ${widget.existing}');

                  if (widget.buying &&
                      initialCashOffer != null &&
                      (!widget.existing ||
                          _barterRecord!.dealStatus == 'new' &&
                              currentUserOffers.isEmpty)) {
                    _currentUserOfferedCash = widget.product!.price!;
                    initialCashOffer = null;
                    _onSubmitTapped(true);
                  }

                  // check products that are not displayed - START
                  List<String> hiddenUserProducts = [];
                  List<String> hiddenRecipientProducts = [];

                  currentUserOffers.forEach((offer) {
                    if (!currentUserItems
                        .any((prod) => prod.productid == offer.productId))
                      hiddenUserProducts.add(offer.productId!);
                  });

                  remoteUserOffers.forEach((offer) {
                    if (!remoteUserItems
                        .any((prod) => prod.productid == offer.productId))
                      hiddenRecipientProducts.add(offer.productId!);
                  });

                  if (hiddenRecipientProducts.isNotEmpty ||
                      hiddenUserProducts.isNotEmpty) {
                    _barterBloc.add(GetHiddenProducuts(
                      hiddenSenderProducts: hiddenUserProducts,
                      hiddenRecipientProducts: hiddenRecipientProducts,
                    ));
                  }

                  // check products that are not displayed - END

                  setState(() {
                    if (widget.product != null) {
                      if (!remoteUserItems.any((prod) =>
                          prod.productid == widget.product!.productid)) {
                        remoteUserItems.insert(0, widget.product!);
                      }
                    }

                    if (widget.initialOffer != null) {
                      if (!currentUserItems.any((prod) =>
                          prod.productid == widget.initialOffer!.productid)) {
                        currentUserItems.insert(0, widget.initialOffer!);
                      }
                    }

                    // add saved products
                    if (unsavedOfferedProducts != null &&
                        unsavedOfferedProducts.isNotEmpty) {
                      unsavedOfferedProducts
                          .forEach((offer) => print('x---> {offer'));
                      print('X===> ${unsavedOfferedProducts.length}');
                      final list = unsavedOfferedProducts
                          .map((data) => BarterProductModel.fromJson(data))
                          .toList();
                      list.forEach((prod) {
                        if (!currentUserOffers
                            .any((item) => item.productId == prod.productId)) {
                          currentUserOffers.add(prod);
                        }
                      });
                    }

                    if (unsavedWantedProducts != null &&
                        unsavedWantedProducts.isNotEmpty) {
                      print('X===> ${unsavedWantedProducts.length}');
                      final list = unsavedWantedProducts
                          .map((data) => BarterProductModel.fromJson(data))
                          .toList();
                      list.forEach((prod) {
                        if (!remoteUserOffers
                            .any((item) => item.productId == prod.productId)) {
                          remoteUserOffers.add(prod);
                        }
                      });
                    }

                    if (unsavedOfferedCash != null) {
                      _currentUserOfferedCash = unsavedOfferedCash;
                    }

                    if (unsavedWantedCash != null) {
                      _remoteUserOfferedCash = unsavedWantedCash;
                    }
                  });
                  _sortProducts();
                }

                if (_existing &&
                    !['withdrawn', 'rejected', 'completed']
                        .contains(_barterRecord!.dealStatus) &&
                    (currentUserOffers.isNotEmpty ||
                        _currentUserOfferedCash != null)) {
                  DialogMessage.show(
                    context,
                    message:
                        'An existing pending barter deal was found for these products.',
                  );
                  _existing = false;
                }
              });
            }

            if (state is GetHiddenProducutsDone) {
              setState(() {
                if (state.hiddenRecipientProducts.isNotEmpty) {
                  state.hiddenRecipientProducts.forEach((prod) => setState(() {
                        print('X====> x ${prod.toJson()}');
                        if (!remoteUserItems
                            .any((item) => item.productid == prod.productid)) {
                          remoteUserItems.add(prod);
                        }
                      }));
                }

                if (state.hiddenSenderProducts.isNotEmpty) {
                  state.hiddenSenderProducts.forEach((prod) => setState(() {
                        print('X====> y ${prod.toJson()}');
                        if (!currentUserItems
                            .any((item) => item.productid == prod.productid)) {
                          print('X====> adding product');
                          currentUserItems.add(prod);
                        }
                      }));
                }
              });

              _sortProducts();
            }

            if (state is BarterError) {
              DialogMessage.show(
                context,
                title: 'Error',
                message: state.message,
              );
            }

            if (state is BarterUserError) {
              await DialogMessage.show(
                context,
                title: 'Error',
                message: state.message,
              );
              Navigator.pop(context);
            }
          },
        ),
        BlocListener(
          bloc: _authBloc,
          listener: (context, state) {
            print('auth bloc current state: $state');
            if (state is AuthLoading) {
              ProgressHUD.of(context)!.show();
              _loading = true;
            } else {
              ProgressHUD.of(context)!.dismiss();
              _loading = false;
            }
            if (state is GetCurrentUsersuccess) {
              setState(() {
                _currentUser = state.user;
                _currentUserModel = state.userModel;
              });

              if (widget.barterRecord == null && _product != null) {
                var thumbnail = '';

                if (_product!.mediaPrimary != null &&
                    _product!.mediaPrimary!.url != null &&
                    _product!.mediaPrimary!.url!.isNotEmpty)
                  thumbnail = _product!.mediaPrimary!.url!;

                if (_product!.mediaPrimary != null &&
                    _product!.mediaPrimary!.url_t != null &&
                    _product!.mediaPrimary!.url_t!.isNotEmpty)
                  thumbnail = _product!.mediaPrimary!.url_t!;

                if (_product!.mediaPrimary == null ||
                    _product!.mediaPrimary!.url!.isEmpty &&
                        _product!.mediaPrimary!.url_t!.isEmpty &&
                        _product!.media != null &&
                        _product!.media!.isNotEmpty)
                  thumbnail = _product!.media!.first.url_t != null
                      ? _product!.media!.first.url_t!
                      : _product!.media!.first.url!;

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
                      u2P1Id: widget.product != null
                          ? widget.product!.productid
                          : null,
                      u2P1Name: widget.product != null
                          ? widget.product!.productname
                          : null,
                      u2P1Price: widget.product != null
                          ? widget.product!.price!.toDouble()
                          : null,
                      u2P1Image: thumbnail,
                      u1P1Id: widget.initialOffer != null
                          ? widget.initialOffer!.productid
                          : null,
                      u1P1Name: widget.initialOffer != null
                          ? widget.initialOffer!.productname
                          : null,
                      u1P1Price: widget.initialOffer != null
                          ? widget.initialOffer!.price!.toDouble()
                          : null,
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
        margin: EdgeInsets.only(top: SizeConfig.paddingTop),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, 0, 16.0, 0),
              height: kToolbarHeight,
              color: kBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () async {
                      if (!_panelClosed) {
                        if (widget.showChatFirst &&
                            chatOnly &&
                            (widget.product != null &&
                                widget.product!.status!.toLowerCase() ==
                                    'completed')) {
                          Navigator.pop(context);
                          return;
                        }
                        _panelController.close();
                        _chatFocusNode.unfocus();
                        application.chatOpened = false;
                        return;
                      }
                      final exit = await _onWillPop();
                      if (exit) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16.0, 5.0, 16.0, 5.0),
                      child: FaIcon(
                        FontAwesomeIcons.chevronLeft,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Barter with $_recipientName',
                    style: Style.subtitle1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Visibility(
                    visible: _barterRecord != null &&
                        ['new', 'completed', 'rejected', 'withdrawn']
                            .contains(_barterRecord!.dealStatus),
                    child: GestureDetector(
                      onTap: () {
                        if (_barterId != null) {
                          DialogMessage.show(
                            context,
                            title: 'Delete Barter',
                            message:
                                'Are you sure you want to delete this Barter?',
                            buttonText: 'Yes',
                            firstButtonClicked: () {
                              unsaveProductsStorage.clear();
                              _barterBloc.add(DeleteBarter(_barterId!));
                            },
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

  _sortProducts() {
    currentUserItems.asMap().forEach((index, prod) {
      if (currentUserOffers.any((bprod) => bprod.productId == prod.productid)) {
        final _prod = currentUserItems.removeAt(index);
        currentUserItems.insert(0, _prod);
      }
    });

    remoteUserItems.asMap().forEach((index, prod) {
      if (remoteUserOffers.any((bprod) => bprod.productId == prod.productid)) {
        final _prod = remoteUserItems.removeAt(index);
        remoteUserItems.insert(0, _prod);
      }
    });
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
                print('--- CURRENT BARTER STATE: $state');
                if (state is BarterLoading) {
                  _loading = true;
                  ProgressHUD.of(context)!.show();
                } else {
                  _loading = false;
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is SendMessageSuccess) {
                  if (_selectedMedia.isNotEmpty) {
                    setState(() {
                      _selectedMedia.clear();
                    });
                  }
                  _messageTextController.clear();
                }

                if (state is GetCurrentUserItemsSuccess) {
                  setState(() {
                    currentUserItems = List.from(state.list);
                  });

                  if (currentUserItems.isNotEmpty) {
                    currentUserItems.sort(
                        (a, b) => a.updated_time!.compareTo(b.updated_time!));
                    _add_currentUserOfferedItems([
                      BarterProductModel.fromProductModel(currentUserItems.last)
                    ]);
                  }
                  // _add_currentUserOfferedItems(currentUserItems
                  //     .map(
                  //         (item) => BarterProductModel.fromProductModel(item))
                  //     .toList());
                }

                if (state is BarterChatInitialized) {
                  if (widget.showChatFirst && widget.product != null) {
                    _panelController.open();

                    _barterBloc
                        .add(MarkMessagesAsRead(_barterRecord!.barterId!));

                    application.chatOpened = true;
                  }
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
                          Visibility(
                            visible: !(widget.showChatFirst &&
                                chatOnly &&
                                (widget.product != null &&
                                    widget.product!.status!.toLowerCase() ==
                                        'completed')),
                            child: Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () {
                                      // if (widget.showChatFirst &&
                                      //     widget.product != null &&
                                      //     widget.product!.status! ==
                                      //         'completed' &&
                                      //     _barterRecord != null &&
                                      //     _barterRecord!.dealStatus == 'inquiry')
                                      //   return;
                                      _panelController.close();
                                      _chatFocusNode.unfocus();

                                      application.chatOpened = false;
                                    },
                                    child: Container(
                                      child: Icon(
                                        Icons.close,
                                        size: 30.0,
                                        color:
                                            // (widget.showChatFirst &&
                                            //         widget.product != null &&
                                            //         widget.product!.status! ==
                                            //             'completed' &&
                                            //         _barterRecord != null &&
                                            //         _barterRecord!.dealStatus ==
                                            //             'inquiry')
                                            //     ? Colors.grey
                                            //     :
                                            kBackgroundColor,
                                      ),
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
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              reverse: true,
                              children: _messages.reversed
                                  .map((msg) => buildChatItem(context, msg,
                                      _currentUser, _recipientName))
                                  .toList(),
                            ),
                          ),
                          // (widget.showChatFirst &&
                          //         widget.product != null &&
                          //         widget.product!.status! == 'completed' &&
                          //         _barterRecord != null &&
                          //         _barterRecord!.dealStatus == 'inquiry')
                          //     ? Container()
                          //     :
                          Container(
                            constraints: BoxConstraints(maxWidth: 500.0),
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ..._buildUserButtons(true),
                                _shouldShowAdd()
                                    ? Expanded(
                                        child: CustomButton(
                                          bgColor: kBackgroundColor,
                                          label: 'Add offer',
                                          onTap: _showCurrentUserItems,
                                          removeMargin: true,
                                        ),
                                      )
                                    : Text(''),
                              ],
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
          Container(
            color: kBackgroundColor,
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _selectedMedia.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.all(8.0),
                        color: Colors.white,
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Attachments',
                                    style: Style.subtitle2.copyWith(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 14)),
                                Spacer(),
                                GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedMedia.clear()),
                                    child: Icon(Icons.close)),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Wrap(
                              children: _selectedMedia
                                  .map((item) => Container(
                                        margin: EdgeInsets.only(right: 5.0),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 100.0,
                                              width: 150.0,
                                              padding: EdgeInsets.all(5.0),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                image: DecorationImage(
                                                  image: FileImage(
                                                    File(item.rawPath!),
                                                  ),
                                                  scale: 1.0,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 5.0,
                                              right: 10.0,
                                              child: InkWell(
                                                onTap: () => setState(() =>
                                                    _selectedMedia
                                                        .remove(item)),
                                                child: Container(
                                                  height: 25.0,
                                                  width: 25.0,
                                                  decoration: BoxDecoration(
                                                    color: Style.secondaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                      size: SizeConfig
                                                              .textScaleFactor *
                                                          16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      )
                    : Container(),
                Container(
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 10.0, 10.0),
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: TextStyle(
                            color: kBackgroundColor,
                            fontSize: SizeConfig.textScaleFactor * 14,
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
                        onTap: _onAddFile,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 10.0,
                          ),
                          child: Icon(
                            FontAwesomeIcons.fileImage,
                            color: Colors.white,
                            size: SizeConfig.textScaleFactor * 17,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _onChatTapped,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 10.0,
                          ),
                          child: Icon(
                            FontAwesomeIcons.paperPlane,
                            color: Colors.white,
                            size: SizeConfig.textScaleFactor * 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _onAddFile() async {
    if (_selectedMedia.length > 9) {
      DialogMessage.show(context,
          message: 'You\'ve exceeded the number of files to attach');
      return;
    }

    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );

    if (selectedMedia != null &&
        validateFileFormat(selectedMedia.storagePath, context)) {
      if (!_selectedMedia.contains(selectedMedia)) {
        setState(() {
          _selectedMedia.add(selectedMedia);
        });
      }
    }
  }

  List<Widget> _buildUserButtons([bool removeChat = false]) {
    if (_barterRecord == null) return [];

    List<Widget> buttons = [];

    switch (_barterRecord!.dealStatus) {
      case 'new':
      case 'rejected':
      case 'withdrawn':
      case 'revoked':
        buttons.add(
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                enabled: (currentUserOffers.isNotEmpty ||
                        _currentUserOfferedCash != null) &&
                    (remoteUserOffers.isNotEmpty ||
                        _remoteUserOfferedCash != null) &&
                    !((currentUserOffers.isEmpty &&
                            _currentUserOfferedCash != null) &&
                        (remoteUserOffers.isEmpty &&
                            _remoteUserOfferedCash != null)),
                removeMargin: true,
                label: 'Make Offer',
                onTap: () => _onSubmitTapped(false),
              ),
            ),
          ),
        );
        break;
      case 'submitted':
        if (_currentUserRole == 'sender') {
          buttons.add(
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
          );
        } else {
          buttons.addAll(
            [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  child: CustomButton(
                    enabled: (currentUserOffers.isNotEmpty ||
                            _currentUserOfferedCash != null) &&
                        (remoteUserOffers.isNotEmpty ||
                            _remoteUserOfferedCash != null),
                    removeMargin: true,
                    label: 'Accept',
                    onTap: () => _onSubmitTapped(false),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  child: CustomButton(
                    removeMargin: true,
                    bgColor: Color(0xFFBB3F03),
                    label: 'Reject',
                    onTap: _onCancelTapped,
                  ),
                ),
              ),
            ],
          );
        }
        break;
      case 'accepted':
        if (_currentUserRole == 'sender') {
          buttons.add(
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
          );
        } else {
          buttons.addAll([
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 8.0),
                child: CustomButton(
                  removeMargin: true,
                  label: 'Complete',
                  onTap: () => _onSubmitTapped(false),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 8.0),
                child: CustomButton(
                  removeMargin: true,
                  bgColor: Color(0xFFBB3F03),
                  label: 'Revoke',
                  onTap: _onCancelTapped,
                ),
              ),
            ),
          ]);
        }
        break;
      case 'completed':
        buttons.addAll([
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: 8.0),
              child: CustomButton(
                removeMargin: true,
                enabled: true,
                label: _userReview != null ? 'View Review' : 'Leave Review',
                onTap: () => _onRateUser(_userReview),
              ),
            ),
          ),
          // Expanded(
          //   child: Container(
          //     margin: EdgeInsets.only(right: 8.0),
          //     child: CustomButton(
          //       enabled: false,
          //       removeMargin: true,
          //       bgColor: Color(0xFFBB3F03),
          //       label: 'Withdraw',
          //       onTap: _onCancelTapped,
          //     ),
          //   ),
          // ),
        ]);
        break;
      default:
    }

    if (!removeChat) {
      buttons.add(
        Expanded(
          child: CustomButton(
            label: 'Chat',
            bgColor: kBackgroundColor,
            textColor: Colors.white,
            onTap: () {
              _panelController.open();
              _barterBloc.add(MarkMessagesAsRead(_barterRecord!.barterId!));
              application.chatOpened = true;
            },
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
    print('x0000x remote user items count: ${remoteUserItems.length}');
    if (_barterRecord == null) return Text('');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarterStatus(),
            Container(
              margin: EdgeInsets.only(bottom: 16.0),
              width: double.infinity,
              height: SizeConfig.screenHeight * 0.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _barterRecord != null &&
                                  _barterRecord!.dealStatus != 'completed'
                              ? 'You will receive:'
                              : 'You have received:',
                          style: Style.subtitle2.copyWith(
                              color: kBackgroundColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${remoteUserOffers.length} Item(s)'),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _buildYouWillReceiveWidgets('recipient'),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _shouldShowAdd() && remoteUserItems.length >= 10,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 500.0,
                      ),
                      child: CustomButton(
                        onTap: () => _showUserItems(
                            application.currentUser!.uid != _recipientUserId!
                                ? _recipientUserId!
                                : _senderUserId!,
                            'Recipient'),
                        label: 'View more products of $_recipientName',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: SizeConfig.screenHeight * 0.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _barterRecord != null &&
                                  _barterRecord!.dealStatus != 'completed'
                              ? 'You will send:'
                              : 'You have sent:',
                          style: Style.subtitle2.copyWith(
                              color: kBackgroundColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${currentUserOffers.length} Item(s)'),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _buildYouWillReceiveWidgets('sender'),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _shouldShowAdd() && currentUserItems.length >= 10,
                    child: Column(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: 500.0,
                          ),
                          child: CustomButton(
                            onTap: () => _showUserItems(
                                application.currentUser!.uid, 'Sender'),
                            label: 'View more of your products',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _shouldShowAdd()
                ? Container(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Tap the (+) icon to add an item to the barter.\nTap the (-) icon to remove an item from the barter.',
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

  _showUserItems(String userId, String userType) async {
    final selectedProducts = userType == 'Sender'
        ? currentUserOffers.map((offer) => offer.productId!).toList()
        : remoteUserOffers.map((offer) => offer.productId!).toList();
    final result = await showDialog<List<ProductModel>?>(
      context: context,
      builder: (dContext) {
        return StatefulBuilder(
          builder: (sbContext, sState) {
            return Dialog(
              child: UserItemsDialog(
                recipientName: _recipientName,
                recipientUserId: _recipientUserId!,
                userId: userId,
                userType: userType,
                selectedProducts: selectedProducts,
                barterId: _barterRecord!.barterId!,
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    if (result.isNotEmpty) {
      setState(() {
        if (userType == 'Sender') {
          result.forEach((prod) {
            if (!currentUserItems
                .any((item) => item.productid == prod.productid)) {
              currentUserItems.insert(0, prod);
            }

            if (!currentUserOffers
                .any((offer) => offer.productId == prod.productid)) {
              currentUserOffers.insert(
                  0, BarterProductModel.fromProductModel(prod));
            }
          });
        } else {
          result.forEach((prod) {
            if (!remoteUserItems
                .any((item) => item.productid == prod.productid)) {
              remoteUserItems.insert(0, prod);
            }

            if (!remoteUserOffers
                .any((offer) => offer.productId == prod.productid)) {
              remoteUserOffers.insert(
                  0, BarterProductModel.fromProductModel(prod));
            }
          });
        }

        _sortProducts();
      });
    }
  }

  List<Widget> _buildYouWillReceiveWidgets(String userType) {
    List<Widget> widgets = [];
    int lastIndex = -1;
    final items = (userType == 'recipient' ? remoteUserItems : currentUserItems)
        .where((prod) => prod.productid != null && prod.productid!.isNotEmpty)
        .toList();
    final offers =
        userType == 'recipient' ? remoteUserOffers : currentUserOffers;

    if (_barterRecord!.dealStatus != 'completed') {
      widgets.addAll(
        items
            .where((prod) => prod.status != 'completed')
            .toList()
            .map((product) {
          return _userItem(
              userType == 'recipient' ? 'remote' : 'sender', product);
        }),
      );

      lastIndex = items.lastIndexWhere(
          (item) => offers.any((offer) => offer.productId == item.productid));
    } else {
      widgets.addAll(
        items
            .where((prod) =>
                offers.any((offer) => prod.productid == offer.productId))
            .toList()
            .map((product) {
          return _userItem(
              userType == 'recipient' ? 'remote' : 'sender', product);
        }),
      );
    }

    widgets.insert(
      lastIndex > -1
          ? lastIndex < widgets.length
              ? lastIndex + 1
              : lastIndex
          : 0,
      Visibility(
        visible: _barterRecord!.dealStatus != 'completed' ||
            (_barterRecord!.dealStatus == 'completed' &&
                (userType == 'recipient'
                        ? _remoteUserOfferedCash
                        : _currentUserOfferedCash) !=
                    null),
        child: Stack(
          children: [
            InkWell(
              onTap: () {
                if (!_shouldShowAdd()) return;

                if (_barterRecord!.dealStatus != 'sold') {
                  _showAddCashDialog(userType);
                }
              },
              child: buildCashItem((userType == 'recipient'
                      ? _remoteUserOfferedCash
                      : _currentUserOfferedCash) ??
                  0),
            ),
            Visibility(
              visible: (userType == 'recipient'
                      ? _remoteUserOfferedCash
                      : _currentUserOfferedCash) ==
                  null,
              child: Positioned.fill(
                child: InkWell(
                  onTap: () {
                    if (!_shouldShowAdd()) return;
                    if (_barterRecord!.dealStatus != 'sold') {
                      _showAddCashDialog(userType);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: _shouldShowAdd()
                        ? Icon(
                            FontAwesomeIcons.plus,
                            color: Colors.white,
                          )
                        : Text(''),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: (userType == 'recipient'
                          ? _remoteUserOfferedCash
                          : _currentUserOfferedCash) !=
                      null &&
                  _shouldShowAdd(),
              child: Positioned(
                top: 10.0,
                right: 10.0,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (userType == 'recipient') {
                        _remoteUserOfferedCash = null;
                      } else {
                        _currentUserOfferedCash = null;
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.minus,
                        color: Colors.white,
                        size: SizeConfig.textScaleFactor * 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return widgets;
  }

  Widget _userItem(String owner, ProductModel product) {
    print('X====> PRODUCT:: ${product.toJson()}');
    var thumbnail = '';

    if (product.media != null && product.media!.isNotEmpty) {
      for (var media in product.media!) {
        thumbnail = media.url_t ?? '';
        if (thumbnail.isNotEmpty) break;
      }
    }

    if (thumbnail.isEmpty) {
      if (product.mediaPrimary != null &&
          product.mediaPrimary!.url_t != null &&
          product.mediaPrimary!.url_t!.isNotEmpty)
        thumbnail = product.mediaPrimary!.url_t!;
    }

    List<BarterProductModel> offers =
        owner == 'remote' ? remoteUserOffers : currentUserOffers;

    return Stack(
      alignment: Alignment.center,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  productId: product.productid ?? '',
                  ownItem: true,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              children: [
                Container(
                  height: SizeConfig.screenHeight * 0.13,
                  width: SizeConfig.screenHeight * 0.17,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    image: DecorationImage(
                      image: thumbnail.isNotEmpty
                          ? CachedNetworkImageProvider(thumbnail)
                          : Image.asset('assets/images/image_placeholder.jpg')
                              .image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5.0),
                  width: SizeConfig.screenHeight * 0.17,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productname != null
                            ? product.productname!.trim()
                            : '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: SizeConfig.textScaleFactor * 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          product.free != null && product.free!
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.only(right: 2.0),
                                  child: Text(
                                    product.currency != null &&
                                            product.currency!.isNotEmpty
                                        ? product.currency!
                                        : application.currentUserModel!
                                                        .currency !=
                                                    null &&
                                                application.currentUserModel!
                                                    .currency!.isNotEmpty
                                            ? application
                                                .currentUserModel!.currency!
                                            : '',
                                    style: TextStyle(
                                      fontSize: SizeConfig.textScaleFactor * 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          Text(
                            product.free != null && product.free!
                                ? 'FREE'
                                : product.price != null
                                    ? oCcy.format(product.price!)
                                    : '0.00',
                            style: TextStyle(
                              fontSize: SizeConfig.textScaleFactor * 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Visibility(
          // visible: [
          //   'completed',
          //   'withdrawn',
          //   'rejected',
          // ].contains(_barterRecord!.dealStatus),
          child: FutureBuilder(
            future: _barterRepo.checkIfBarterable(
                _recipientUserId! == application.currentUser!.uid
                    ? _senderUserId!
                    : _recipientUserId!,
                product.productid!,
                _barterId!),
            builder: (context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (!snapshot.data!) {
                  return Positioned.fill(
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Center(
                        child: Text(
                          'UNAVAILABLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Visibility(
                    visible: !offers.any((BarterProductModel prod) =>
                        prod.productId == product.productid),
                    child: Positioned.fill(
                      child: InkWell(
                        onTap: !offers.any((BarterProductModel prod) =>
                                    prod.productId == product.productid) &&
                                _shouldShowAdd()
                            ? () async {
                                final barterable =
                                    await _barterRepo.checkIfBarterable(
                                        product.userid!,
                                        product.productid!,
                                        _barterRecord!.barterId!);

                                if (!barterable) {
                                  await DialogMessage.show(
                                    context,
                                    message:
                                        'You can\'t add this product to the barter as you already have a another pending barter with ${_recipientName.toUpperCase()} for this ${product.productname}',
                                  );

                                  return;
                                }

                                final item =
                                    BarterProductModel.fromProductModel(
                                        product);
                                if (owner == 'remote') {
                                  _addWantedItems([item]);
                                } else {
                                  _add_currentUserOfferedItems([item]);
                                }

                                _sortProducts();
                              }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: _shouldShowAdd()
                              ? Icon(
                                  FontAwesomeIcons.plus,
                                  color: Colors.white,
                                )
                              : Text(''),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        // Visibility(
        //   visible: !offers.any((BarterProductModel prod) =>
        //           prod.productId == product.productid) &&
        //       ![
        //         'completed',
        //         'withdrawn',
        //         'rejected',
        //       ].contains(_barterRecord!.dealStatus),
        //   child: Positioned.fill(
        //     child: InkWell(
        //       onTap: !offers.any((BarterProductModel prod) =>
        //                   prod.productId == product.productid) &&
        //               _shouldShowAdd()
        //           ? () async {
        //               final barterable = await _barterRepo.checkIfBarterable(
        //                   _recipientUserId!,
        //                   product.productid!,
        //                   _barterRecord!.barterId!);

        //               if (!barterable) {
        //                 await DialogMessage.show(
        //                   context,
        //                   message:
        //                       'You can\'t add this product to the barter as you already have a another pending barter with ${_recipientName.toUpperCase()} for this ${product.productname}',
        //                 );

        //                 return;
        //               }

        //               final item = BarterProductModel.fromProductModel(product);
        //               if (owner == 'remote') {
        //                 _addWantedItems([item]);
        //               } else {
        //                 _add_currentUserOfferedItems([item]);
        //               }

        //               _sortProducts();
        //             }
        //           : null,
        //       child: Container(
        //         decoration: BoxDecoration(
        //           color: Colors.black.withOpacity(0.5),
        //           borderRadius: BorderRadius.circular(20.0),
        //         ),
        //         child: _shouldShowAdd()
        //             ? Icon(
        //                 FontAwesomeIcons.plus,
        //                 color: Colors.white,
        //               )
        //             : Text(''),
        //       ),
        //     ),
        //   ),
        // ),
        Visibility(
          visible:
              _barterRecord!.dealStatus == 'completed' && owner == 'remote',
          child: Positioned(
            top: 10.0,
            right: 10.0,
            child: InkWell(
              onTap: () {
                _productToReview = BarterProductModel.fromProductModel(product);
                _barterBloc.add(
                    GetProductReview(product.productid!, _currentUser!.uid));
              },
              child: Container(
                padding: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBackgroundColor,
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: SizeConfig.textScaleFactor * 14,
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: offers.any((BarterProductModel prod) {
                return prod.productId == product.productid;
              }) &&
              _shouldShowAdd(),
          child: Positioned(
            top: 10.0,
            right: 10.0,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (owner == 'remote') {
                    remoteUserOffers.removeWhere(
                        (prod) => prod.productId == product.productid);
                  } else {
                    currentUserOffers.removeWhere(
                        (prod) => prod.productId == product.productid);
                  }
                  _sortProducts();
                });
              },
              child: Container(
                padding: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.minus,
                    color: Colors.white,
                    size: SizeConfig.textScaleFactor * 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _onRateProduct(ProductReviewModel? review, BarterProductModel item) async {
    final rating = await showDialog(
      context: context,
      builder: (context) {
        final _reviewTextController =
            TextEditingController(text: review != null ? review.review : '');
        num _rating = review != null ? review.rating ?? 0 : 0.0;
        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return Dialog(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rate Product',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kBackgroundColor,
                              fontSize: SizeConfig.textScaleFactor * 16.0,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: kBackgroundColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.0),
                    Container(
                      child: Center(
                          child: Text(
                        item.productName ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RatingBar.builder(
                          initialRating:
                              review != null ? review.rating!.toDouble() : 0.0,
                          minRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 20,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) =>
                              setState(() => _rating = rating),
                        ),
                        Text('${_rating.toStringAsFixed(1)}'),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    CustomTextFormField(
                      label: 'Review',
                      hintText: 'Write a user review',
                      controller: _reviewTextController,
                      textColor: kBackgroundColor,
                      maxLines: 3,
                    ),
                    CustomButton(
                      enabled: _rating > 0,
                      bgColor: kBackgroundColor,
                      label: review == null ? 'SUBMIT' : 'UPDATE',
                      onTap: () {
                        Navigator.pop(context, {
                          'rating': _rating,
                          'review': _reviewTextController.text.trim(),
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // TODO: rate product
    if (rating != null) {
      _barterBloc.add(RateProduct(ProductReviewModel(
        productid: item.productId,
        productname: item.productName,
        image_url_t: item.imgUrl,
        userid: _currentUserModel!.userid,
        display_name: _currentUserModel!.display_name,
        rating: rating['rating'] + 0.0,
        review: rating['review'] as String?,
      )));
    }

    _productToReview = null;
  }

  bool _shouldShowAdd() {
    if (_barterRecord == null) return false;

    if (_currentUserRole == 'sender')
      return ['new', 'withdrawn', 'rejected', 'revoked']
          .contains(_barterRecord!.dealStatus);
    else
      return !['new', 'submitted', 'accepted', 'completed']
          .contains(_barterRecord!.dealStatus);
  }

  Widget _buildBarterStatus() {
    currentUserOffers.forEach((cuOffer) => print('___-=> ${cuOffer.toJson()}'));
    if (_barterRecord == null) return Container();
    print('current barter status: ${_barterRecord!.dealStatus}');
    var message = '';
    switch (_barterRecord!.dealStatus) {
      case 'new':
        message = 'This proposal has not been submitted';
        break;
      case 'submitted':
        if (_currentUserRole == 'sender')
          message = 'You have submitted this offer';
        else
          message = '$_recipientName submitted this offer';
        break;
      case 'rejected':
        if (_currentUserRole == 'sender')
          message = '$_recipientName has rejected this offer';
        else
          message = 'You have rejected this offer';
        break;
      case 'withdrawn':
        if (_currentUserRole == 'sender')
          message = 'You have withdrawn this offer';
        else
          message = '$_recipientName withdrew this offer';
        break;
      case 'accepted':
        if (_currentUserRole == 'sender')
          message = '$_recipientName accepted this offer';
        else
          message = 'You have accepted this offer';
        break;
      case 'revoked':
        if (_currentUserRole == 'sender')
          message = '$_recipientName revoked acceptance';
        else
          message = 'You have revoked your acceptance';
        break;
      default:
        message = 'This deal has been completed';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: kDangerColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Style.bodyText1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  INTL.DateFormat.yMMMd().format(_barterRecord!.dealDate!),
                  textAlign: TextAlign.center,
                  style: Style.bodyText1.copyWith(
                    color: Colors.white,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.0),
          Visibility(
            visible: _barterRecord!.dealStatus == 'completed',
            child: GestureDetector(
              onTap: () => _onRateUser(_userReview),
              child: Text(
                'Rate User',
                style: TextStyle(
                  color: kBackgroundColor,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _onRateUser(UserReviewModel? review) async {
    final _reviewTextController = TextEditingController();
    num _rating = 0;
    if (review != null) {
      _reviewTextController.text = review.review ?? '';
      _rating = review.rating ?? 0;
    }

    final rating = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rate User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBackgroundColor,
                            fontSize: SizeConfig.textScaleFactor * 15.0,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: kBackgroundColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBar.builder(
                        initialRating:
                            review != null ? review.rating!.toDouble() : 0,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 20,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _rating = rating;
                          });
                        },
                      ),
                      Text(_rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 16.0)),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  CustomTextFormField(
                    label: 'Review',
                    hintText: 'Write a user review',
                    controller: _reviewTextController,
                    textColor: kBackgroundColor,
                    maxLines: 3,
                  ),
                  CustomButton(
                    bgColor: kBackgroundColor,
                    label: review == null ? 'SUBMIT' : 'UPDATE',
                    onTap: () async {
                      if (_rating < 1) {
                        await DialogMessage.show(
                          context,
                          message: 'Please rate the user with stars',
                        );

                        return;
                      }
                      Navigator.pop(context, {
                        'rating': _rating,
                        'review': _reviewTextController.text.trim(),
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (rating != null) {
      _barterBloc.add(AddUserReview(
        UserReviewModel(
          rating: rating['rating'] as double,
          review: rating['review'] as String?,
          reviewerid: _currentUserModel!.userid,
          reviewername: _currentUserModel!.display_name,
          userid: _recipientUserId == _currentUserModel!.userid
              ? _senderUserId
              : _recipientUserId,
          username: _recipientName,
        ),
      ));
    }
  }

  Widget _buildMinimizedView() {
    List<Widget> wantWidgets = [];
    List<Widget> offerWidgets = [];

    if (widget.showChatFirst &&
        chatOnly &&
        (widget.product != null &&
            widget.product!.status!.toLowerCase() == 'completed')) {
      return FittedBox(
        child: Container(
          margin: EdgeInsets.only(top: 10.0),
          height: (SizeConfig.screenHeight * 0.25 + 10) -
              (kToolbarHeight + SizeConfig.paddingTop),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: (SizeConfig.screenHeight * 0.25) -
                      (kToolbarHeight + SizeConfig.paddingTop),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: kBackgroundColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      image: widget.product!.media!.first.url_t != null
                          ? NetworkImage(widget.product!.media!.first.url_t!)
                          : AssetImage('assets/images/image_placeholder.jpg')
                              as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Text(
                'COMPLETED',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: kBackgroundColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_remoteUserOfferedCash != null) {
      wantWidgets.add(
        InkWell(
          onTap: () {
            if (_barterRecord!.dealStatus != 'sold') {
              _showAddCashDialog('recipient');
            }
          },
          child: Stack(
            children: [
              Container(
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
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: SizeConfig.textScaleFactor * 11,
                  width: double.infinity,
                  color: kBackgroundColor,
                  child: FittedBox(
                    child: Text(
                      '${application.currentUserModel!.currency ?? ''} ${_remoteUserOfferedCash!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.textScaleFactor * 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    wantWidgets.addAll(remoteUserOffers.reversed.map((want) {
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

    if (_currentUserOfferedCash != null) {
      offerWidgets.add(
        InkWell(
          onTap: () => _showAddCashDialog('user'),
          child: Stack(
            children: [
              Container(
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
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: SizeConfig.textScaleFactor * 11,
                  width: double.infinity,
                  color: kBackgroundColor,
                  child: FittedBox(
                    child: Text(
                      '${application.currentUserModel!.currency ?? ''} ${_currentUserOfferedCash!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: SizeConfig.textScaleFactor * 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    offerWidgets.addAll(
      currentUserOffers.reversed.map((offer) {
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

    // if (widget.showChatFirst &&
    //     widget.product != null &&
    //     widget.product!.status! == 'completed' &&
    //     _barterRecord != null &&
    //     _barterRecord!.dealStatus == 'inquiry') {
    //   var thumbnail = '';
    //   final product = widget.product!;

    //   if (product.media != null && product.media!.isNotEmpty) {
    //     for (var media in product.media!) {
    //       thumbnail = media.url_t ?? '';
    //       if (thumbnail.isNotEmpty) break;
    //     }
    //   }

    //   if (thumbnail.isEmpty) {
    //     if (product.mediaPrimary != null &&
    //         product.mediaPrimary!.url_t != null &&
    //         product.mediaPrimary!.url_t!.isNotEmpty)
    //       thumbnail = product.mediaPrimary!.url_t!;
    //   }

    //   return Container(
    //     padding: EdgeInsets.all(20.0),
    //     height: (SizeConfig.screenHeight * 0.3) -
    //         (kToolbarHeight + SizeConfig.paddingTop),
    //     width: double.infinity,
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Container(
    //               height: SizeConfig.textScaleFactor * 65,
    //               width: SizeConfig.textScaleFactor * 65,
    //               decoration: BoxDecoration(
    //                 border: Border.all(
    //                   color: kBackgroundColor,
    //                   width: 1.5,
    //                 ),
    //                 borderRadius: BorderRadius.circular(8.0),
    //                 image: DecorationImage(
    //                   image: thumbnail.isNotEmpty
    //                       ? NetworkImage(thumbnail)
    //                       : AssetImage('assets/images/image_placeholder.jpg')
    //                           as ImageProvider<Object>,
    //                   fit: BoxFit.cover,
    //                 ),
    //               ),
    //             ),
    //             SizedBox(width: SizeConfig.textScaleFactor * 30),
    //             Column(
    //               children: [
    //                 Text(product.productname ?? ''),
    //                 Text(product.price != null
    //                     ? oCcy.format(product.price!)
    //                     : ''),
    //               ],
    //             ),
    //           ],
    //         )
    //       ],
    //     ),
    //   );
    // }

    return Container(
      height:
          //  (widget.showChatFirst &&
          //         widget.product != null &&
          //         widget.product!.status! == 'completed' &&
          //         _barterRecord != null &&
          //         _barterRecord!.dealStatus == 'inquiry')
          //     ? (SizeConfig.screenHeight * 0.25) -
          //         (kToolbarHeight + SizeConfig.paddingTop)
          //     :
          (SizeConfig.screenHeight * 0.3) -
              (kToolbarHeight + SizeConfig.paddingTop),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10.0,
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  _panelController.close();
                  _chatFocusNode.unfocus();
                  application.chatOpened = false;
                },
                child: Container(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: SizeConfig.screenHeight * 0.1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      _barterRecord!.dealStatus != 'completed'
                                          ? 'You will receive'
                                          : 'You received',
                                      style: TextStyle(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 13,
                                        color: kBackgroundColor,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Expanded(
                                    child: wantWidgets.isNotEmpty
                                        ? Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: GridView.count(
                                              scrollDirection: Axis.horizontal,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 2.0),
                                              mainAxisSpacing: 5.0,
                                              crossAxisCount: 1,
                                              reverse: true,
                                              children: wantWidgets,
                                            ),
                                          )
                                        : Container(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(10.0, 17.0, 10.0, 0.0),
                            child: Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.sync_alt_outlined,
                                size: SizeConfig.textScaleFactor * 15,
                                color: kBackgroundColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: SizeConfig.screenHeight * 0.1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _barterRecord!.dealStatus != 'completed'
                                          ? 'You will send'
                                          : 'You sent',
                                      style: TextStyle(
                                        fontSize:
                                            SizeConfig.textScaleFactor * 13,
                                        color: kBackgroundColor,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  Expanded(
                                    child: offerWidgets.isNotEmpty
                                        ? Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: GridView.count(
                                              scrollDirection: Axis.horizontal,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 2.0),
                                              mainAxisSpacing: 5.0,
                                              crossAxisCount: 1,
                                              reverse: true,
                                              children: offerWidgets,
                                            ),
                                          )
                                        : Container(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // (widget.showChatFirst &&
                      //         widget.product != null &&
                      //         widget.product!.status! == 'completed' &&
                      //         _barterRecord != null &&
                      //         _barterRecord!.dealStatus == 'inquiry')
                      //     ? Container()
                      //     :
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 8.0),
                          child: Text(
                            _barterRecord != null &&
                                    _barterRecord!.dealStatus != 'completed'
                                ? 'Tap here to edit your offer'
                                : 'Tap here to view barter',
                            style: TextStyle(
                              fontSize: SizeConfig.textScaleFactor * 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _offersChanged() {
    bool changed = false;
    origCurrentUserOffers.forEach((oOffer) {
      final stillExists =
          currentUserOffers.any((offer) => offer.productId == oOffer.productId);
      if (!stillExists) changed = true;
    });

    origRemoteUserOffers.forEach((oWant) {
      final stillExists =
          remoteUserOffers.any((want) => want.productId == oWant.productId);
      if (!stillExists) changed = true;
    });

    if ((origCurrentUserOffers.length != currentUserOffers.length) ||
        (origRemoteUserOffers.length != remoteUserOffers.length))
      changed = true;

    if ((_origCurrentUserOfferedCash != _currentUserOfferedCash) ||
        (_origRemoteUserOfferedCash != _remoteUserOfferedCash)) changed = true;

    return changed;
  }

  _onSubmitTapped(bool forced) async {
    ProgressHUD.of(_scaffoldKey.currentContext!)!.show();
    _existing = false;
    if (!forced) {
      if (_barterRecord != null && _barterRecord!.dealStatus == 'sold') {
        ProgressHUD.of(_scaffoldKey.currentContext!)!.dismiss();
        return;
      }

      if (!_closing) {
        String message =
            'You are about to submit this offer\n\nDo you want to continue?';

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

        if (_barterRecord!.dealStatus == 'revoked') {
          if (_currentUserRole == 'sender') {
            message =
                'You are about to make a new offer\n\nDo you want to continue?';
          } else {
            message =
                'You are about to counter offer\n\nDo you want to continue?';
          }
        }

        if (_barterRecord!.dealStatus == 'completed') {
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

        if (shouldContinue == null || !shouldContinue) {
          ProgressHUD.of(_scaffoldKey.currentContext!)!.dismiss();
          return;
        }
      }
    }

    final itemsInBarter = remoteUserOffers + currentUserOffers;
    List<BarterProductModel> unavailableItems = [];

    await Future.forEach(itemsInBarter, (BarterProductModel item) async {
      final barterable = await _barterRepo.checkIfBarterable(
          item.userId!, item.productId!, _barterId!);
      if (!barterable) {
        unavailableItems.add(item);
      }
    });

    if (unavailableItems.length > 0) {
      DialogMessage.show(
        context,
        message:
            'There are unavailable items added to the barter, please make sure all items are available to proceed.',
      );

      ProgressHUD.of(_scaffoldKey.currentContext!)!.dismiss();
      return;
    }

    List<BarterProductModel> _deletedProducts = [];
    if (origCurrentUserOffers != currentUserOffers) {
      origCurrentUserOffers.forEach((bProd) {
        if (!currentUserOffers
            .any((obProd) => obProd.productId == bProd.productId)) {
          _deletedProducts.add(bProd);
        }
      });
    }

    if (origRemoteUserOffers != remoteUserOffers) {
      origRemoteUserOffers.forEach((owProd) {
        if (!remoteUserOffers
            .any((oProd) => oProd.productId == owProd.productId)) {
          _deletedProducts.add(owProd);
        }
      });
    }

    if (_origCurrentUserOfferedCash != _currentUserOfferedCash) {
      if (_currentUserOfferedCash != null) {
        _barterBloc.add(
          AddCashOffer(
            barterId: _barterRecord!.barterId!,
            userId: _currentUser!.uid,
            amount: _currentUserOfferedCash!,
            currency: 'PHP',
          ),
        );
      } else {
        _barterBloc.add(
          DeleteCashOffer(
            barterId: _barterRecord!.barterId!,
            productId: _currentUserOfferedCashModel!.productId!,
          ),
        );
      }
    }

    if (_origRemoteUserOfferedCash != _remoteUserOfferedCash) {
      if (_remoteUserOfferedCash != null) {
        _barterBloc.add(
          AddCashOffer(
            barterId: _barterRecord!.barterId!,
            userId: _currentUser!.uid == _senderUserId
                ? _recipientUserId!
                : _senderUserId!,
            amount: _remoteUserOfferedCash!,
            currency: 'PHP',
          ),
        );
      } else {
        _barterBloc.add(
          DeleteCashOffer(
            barterId: _barterRecord!.barterId!,
            productId: _remoteUserOfferedCashModel!.productId!,
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
      products: remoteUserOffers + currentUserOffers,
    ));

    switch (_barterRecord!.dealStatus) {
      case 'rejected':
      case 'withdrawn':
      case 'revoked':
        if (_currentUserRole == 'recipient') {
          _barterBloc.add(CounterOffer(_barterRecord!.barterId!, null));
        } else {
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        }
        break;
      case 'new':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'submitted'));
        break;
      case 'submitted':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'accepted'));
        break;
      case 'accepted':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'completed'));
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
          ? 'You are about to reject/revoke this offer, do you want to continue?'
          : 'You are about to withdraw this barter, do you want to continue?',
      title: 'Warning',
      buttonText: 'Yes',
      secondButtonText: 'No',
      result1: true,
      result2: false,
    );

    if (!shouldContinue) {
      ProgressHUD.of(_scaffoldKey.currentContext!)!.dismiss();
      return;
    }

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
        if (_currentUserRole == 'recipient')
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'revoked'));
        else
          _barterBloc
              .add(UpdateBarterStatus(_barterRecord!.barterId!, 'withdrawn'));
        break;
      case 'new':
        _barterBloc
            .add(UpdateBarterStatus(_barterRecord!.barterId!, 'withdrawn'));
        break;
      default:
    }

    ProgressHUD.of(_scaffoldKey.currentContext!)!.dismiss();
  }

  Container _buildBarterList({
    required String label,
    required List<Widget> items,
    Widget? labelAction,
    bool showAddBtn = true,
    Function()? addBtnTapped,
  }) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 0.0),
            child: Row(
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
          ),
          Container(
            padding: EdgeInsets.only(top: 10.0),
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

  _showRemoteUserItems() {
    print(remoteUserItems.length);
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
                    label: 'Select item(s) from $_recipientName',
                    labelAction: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        FontAwesomeIcons.times,
                        color: kBackgroundColor,
                      ),
                    ),
                    items: [
                      ...remoteUserItems.map((item) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 8.0, bottom: 5.0),
                              child: BarterListItem(
                                product: item,
                                hideLikeBtn: true,
                                onTapped: () {
                                  if (remoteUserOffers.any((product) =>
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
                              visible: remoteUserOffers.any((product) =>
                                  product.productId == item.productid),
                              child: Container(
                                margin: EdgeInsets.only(right: 8.0),
                                width: SizeConfig.screenHeight * 0.17,
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
                                width: SizeConfig.screenHeight * 0.17,
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
                            //   _add_currentUserOfferedCashItems(selectedItems
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
                          label: _remoteUserOfferedCash != null
                              ? 'Edit Requested Cash'
                              : 'Request Cash',
                          bgColor: Color(0xFFBB3F03),
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCashDialog('recipient');
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
    print('0--recipient cash--> $_remoteUserOfferedCash');
    print('0--user cash--> $_currentUserOfferedCash');

    final _cFormKey = GlobalKey<FormState>();
    var amount = await showDialog(
      context: context,
      builder: (dContext) {
        if (from == 'recipient') {
          amounTextController.text = _remoteUserOfferedCash != null
              ? _remoteUserOfferedCash!.toStringAsFixed(2)
              : '';
        } else {
          amounTextController.text = _currentUserOfferedCash != null
              ? _currentUserOfferedCash!.toStringAsFixed(2)
              : '';
        }

        return StatefulBuilder(builder: (ctx, sState) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
              width: SizeConfig.screenWidth * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    from == 'recipient' ? 'Request Cash' : 'Offer Cash',
                    style: Style.subtitle1.copyWith(color: kBackgroundColor),
                  ),
                  SizedBox(height: 10.0),
                  Form(
                    key: _cFormKey,
                    child: CustomTextFormField(
                      color: kBackgroundColor,
                      // label: 'Enter Amount',
                      hintText: '0.00',
                      controller: amounTextController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      maxLength: 14,
                      validator: (val) {
                        if (val != null && val.isEmpty)
                          return 'Required';
                        else if (val != null && val.isNotEmpty) {
                          final amount = double.parse(val.replaceAll(',', ''));
                          if (amount > 100000000) {
                            return 'Max amount is 100,000,000.00';
                          }
                        }

                        return null;
                      },
                      inputFormatters: [
                        CurrencyTextInputFormatter(symbol: ''),
                      ],
                      prefix: Container(
                        margin: EdgeInsets.only(right: 5.0),
                        child: Text(
                          application.currentUserModel!.currency ?? 'PHP',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          bgColor: kBackgroundColor,
                          textColor: Colors.white,
                          label: 'Add Cash',
                          onTap: () {
                            if (!_cFormKey.currentState!.validate())
                              return null;
                            else {
                              final amt = amounTextController.text
                                  .trim()
                                  .replaceAll(
                                      application.currentUserModel!.currency ??
                                          'PHP',
                                      '');
                              final amount = num.parse(amt.replaceAll(',', ''));
                              amounTextController.clear();
                              Navigator.pop(context, amount);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: CustomButton(
                          bgColor: Colors.red.shade400,
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
        });
      },
    );

    if (amount != null) {
      amount = amount as num;

      setState(() {
        if (from == 'recipient') {
          _remoteUserOfferedCash = amount;
        } else {
          _currentUserOfferedCash = amount;
        }
      });
    }
  }

  _addWantedItems(List<BarterProductModel> items) {
    setState(() {
      // remoteUserOffers.addAll(items);
      items.forEach((item) {
        if (!remoteUserOffers.any((bProd) => bProd.productId == item.productId))
          remoteUserOffers.add(item);
      });
    });
    if (items.length == 1)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${items.first.productName} has been added to products you will receive.'),
        duration: Duration(seconds: 1),
      ));
  }

  _add_currentUserOfferedItems(List<BarterProductModel> items) {
    setState(() {
      items.forEach((item) {
        if (!currentUserOffers
            .any((bProd) => bProd.productId == item.productId))
          currentUserOffers.add(item);
      });
    });
    if (items.length == 1)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${items.first.productName} has been added to products you will send.'),
        duration: Duration(seconds: 1),
      ));
  }

  _showCurrentUserItems() {
    showMaterialModalBottomSheet(
        isDismissible: true,
        context: context,
        builder: (context) {
          List<ProductModel> selectedItems = [];
          return StatefulBuilder(builder: (context, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
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
                  currentUserItems.isNotEmpty
                      ? _buildBarterList(
                          label: 'Select from your store',
                          labelAction: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              FontAwesomeIcons.times,
                              color: kBackgroundColor,
                            ),
                          ),
                          items: currentUserItems.map((item) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                  margin:
                                      EdgeInsets.only(right: 8.0, bottom: 5.0),
                                  child: BarterListItem(
                                    product: item,
                                    hideLikeBtn: true,
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
                                  visible: currentUserOffers.any((product) =>
                                      product.productId == item.productid),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 8.0),
                                    width: SizeConfig.screenHeight * 0.17,
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
                                    width: SizeConfig.screenHeight * 0.17,
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
                          showAddBtn: false,
                        )
                      : Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'You do not have any products to offer',
                                style: TextStyle(
                                  fontSize: SizeConfig.textScaleFactor * 14,
                                  color: kBackgroundColor,
                                ),
                              ),
                              SizedBox(height: 12.0),
                              RichText(
                                  text: TextSpan(
                                style: TextStyle(
                                  fontSize: SizeConfig.textScaleFactor * 14,
                                  color: kBackgroundColor,
                                ),
                                children: [
                                  TextSpan(text: 'Tap '),
                                  TextSpan(
                                    text: 'here',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: SizeConfig.textScaleFactor * 14,
                                    ),
                                    recognizer: new TapGestureRecognizer()
                                      ..onTap = () async {
                                        Navigator.pop(context);
                                        final data = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                settings: RouteSettings(
                                                    arguments:
                                                        Map<String, dynamic>()),
                                                builder: (context) =>
                                                    ProductAddScreen()));
                                        if (data != false) {
                                          _barterBloc
                                              .add(GetCurrentUserItems());
                                        }
                                      },
                                  ),
                                  TextSpan(text: ' to add a product'),
                                ],
                              )),
                            ],
                          ),
                        ),
                  currentUserItems.isNotEmpty
                      ? Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 20.0),
                          child: Center(
                            child: RichText(
                                text: TextSpan(
                              style: TextStyle(
                                fontSize: SizeConfig.textScaleFactor * 14,
                                color: kBackgroundColor,
                              ),
                              children: [
                                TextSpan(text: 'Tap '),
                                TextSpan(
                                  text: 'here',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: SizeConfig.textScaleFactor * 14,
                                  ),
                                  recognizer: new TapGestureRecognizer()
                                    ..onTap = () async {
                                      Navigator.pop(context);
                                      final data = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              settings: RouteSettings(
                                                  arguments:
                                                      Map<String, dynamic>()),
                                              builder: (context) =>
                                                  ProductAddScreen()));
                                      if (data != false) {
                                        _barterBloc.add(GetCurrentUserItems());
                                      }
                                    },
                                ),
                                TextSpan(text: ' to add a new offer'),
                              ],
                            )),
                          ),
                        )
                      : Text(''),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Add Selected Item(s)',
                          enabled: selectedItems.length > 0,
                          bgColor: kBackgroundColor,
                          textColor: Colors.white,
                          onTap: () {
                            _add_currentUserOfferedItems(selectedItems
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
                          label: _currentUserOfferedCash != null
                              ? 'Edit ${_currentUserRole == 'recipient' ? 'Requested' : 'Offered'} Cash'
                              : '${_currentUserRole == 'recipient' ? 'Request' : 'Offer'} Cash',
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

  _onChatTapped() {
    if (_messageTextController.text.trim().isEmpty && _selectedMedia.isEmpty)
      return;

    _barterBloc.add(
      SendMessage(
        ChatMessageModel(
          barterId: _barterId,
          message: _messageTextController.text.trim(),
          userId: _currentUserModel!.userid,
          userName: _currentUserModel!.display_name,
          imagesFile: _selectedMedia,
        ),
      ),
    );

    if (_chatFocusNode.hasFocus) _chatFocusNode.unfocus();
  }
}
