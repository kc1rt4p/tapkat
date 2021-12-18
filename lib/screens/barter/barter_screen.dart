import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/schemas/barter_record.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

import 'bloc/barter_bloc.dart';

class BarterScreen extends StatefulWidget {
  final Map<String, dynamic> mappedProductDetails;

  const BarterScreen({
    Key? key,
    required this.mappedProductDetails,
  }) : super(key: key);

  @override
  _BarterScreenState createState() => _BarterScreenState();
}

class _BarterScreenState extends State<BarterScreen> {
  late Map<String, dynamic> _mappedProductDetails;
  late AuthBloc _authBloc;
  final _barterBloc = BarterBloc();
  List<dynamic> offers = [];
  List<dynamic> wants = [];
  late String _participantName;
  List<dynamic> participantItems = [];
  List<dynamic> userItems = [];
  User? _currentUser;
  BarterRecord? _barterRecord;
  StreamSubscription<List<BarterRecord?>>? _barterStreamSub;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _mappedProductDetails = widget.mappedProductDetails;

    _participantName = _mappedProductDetails['ownerName'] as String;
    _participantName = _participantName[0].toUpperCase() +
        _participantName.substring(1).toLowerCase();
    _authBloc.add(GetCurrentuser());

    setState(() {
      wants.add({
        'productid': _mappedProductDetails['productId'],
        'media_primary': {
          'url': _mappedProductDetails['imgUrl'],
        },
        'productname': _mappedProductDetails['productName'],
        'price': double.parse(
            (_mappedProductDetails['price'] as String).substring(1)),
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _barterStreamSub!.cancel();
    _barterStreamSub = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xFFEBFBFF),
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
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

                if (state is BarterInitialized) {
                  setState(() {
                    participantItems = state.user2Products;
                    userItems = state.userProducts;
                  });
                  _barterStreamSub = state.barterStream.listen((barterRecord) {
                    if (barterRecord.first != null) {
                      setState(() {
                        _barterRecord = barterRecord.first;
                      });
                    }
                  });
                }
              },
            ),
            BlocListener(
              bloc: _authBloc,
              listener: (context, state) {
                if (state is AuthLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }
                if (state is GetCurrentUsersuccess) {
                  setState(() {
                    _currentUser = state.user;
                  });

                  _barterBloc.add(
                    InitializeBarter(
                      createBarterRecordData(
                        barterid: _currentUser!.uid +
                            _mappedProductDetails['ownerId'] +
                            _mappedProductDetails['productId'],
                        userid1: _currentUser!.uid,
                        userid2: _mappedProductDetails['ownerId'],
                        barterNo: _mappedProductDetails[''],
                        u1P1Name: _mappedProductDetails['productName'],
                        u1P1Price: double.parse(
                            (_mappedProductDetails['price'] as String)
                                .substring(1)),
                        u1P1Image: _mappedProductDetails['imgUrl'],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          child: Container(
            child: Column(
              children: [
                CustomAppBar(label: 'Barter with $_participantName'),
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
                              label:
                                  'You want this item(s) from $_participantName',
                              items: wants.map((item) {
                                return Container(
                                  margin:
                                      EdgeInsets.only(right: 8.0, bottom: 5.0),
                                  child: Stack(
                                    children: [
                                      BarterListItem(
                                        hideLikeBtn: true,
                                        itemName: item['productname'],
                                        itemPrice: item['currency'] ??
                                            '\$' +
                                                ((item['price'] + 0.00)
                                                        as double)
                                                    .toStringAsFixed(2),
                                        imageUrl: item['imgUrl'] ??
                                                item['media_primary'] != null
                                            ? (item['media_primary']
                                                as Map<String, dynamic>)['url']
                                            : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                                      ),
                                      Positioned(
                                        top: 5.0,
                                        right: 5.0,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              wants.removeWhere((product) =>
                                                  product['productid'] ==
                                                  item['productid']);
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
                              label: 'Your offer',
                              labelAction: Text(
                                '${offers.length} Item(s) Offered',
                              ),
                              items: offers.map((item) {
                                return Container(
                                  margin:
                                      EdgeInsets.only(right: 8.0, bottom: 5.0),
                                  child: Stack(
                                    children: [
                                      BarterListItem(
                                        hideLikeBtn: true,
                                        itemName: item['productname'],
                                        itemPrice: item['currency'] ??
                                            '\$' +
                                                ((item['price'] + 0.00)
                                                        as double)
                                                    .toStringAsFixed(2),
                                        imageUrl: item['imgUrl'] ??
                                                item['media_primary'] != null
                                            ? (item['media_primary']
                                                as Map<String, dynamic>)['url']
                                            : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                                      ),
                                      Positioned(
                                        top: 5.0,
                                        right: 5.0,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              offers.removeWhere((product) =>
                                                  product['productid'] ==
                                                  item['productid']);
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
                              addBtnTapped: () => _showUserItems(),
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
                      CustomButton(
                        label: 'Send Proposal to $_participantName',
                        bgColor: Color(0xFFBB3F03),
                        textColor: Colors.white,
                        onTap: () {},
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
    );
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
              Text(
                label,
                style: Style.subtitle2.copyWith(
                    color: kBackgroundColor, fontWeight: FontWeight.bold),
              ),
              Spacer(),
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
          List<dynamic> selectedItems = [];
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
                              itemName: item['productname'],
                              itemPrice: item['currency'] +
                                  ((item['price'] + 0.00) as double)
                                      .toStringAsFixed(2),
                              imageUrl: item['media_primary'] != null
                                  ? (item['media_primary']
                                      as Map<String, dynamic>)['url']
                                  : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                              onTapped: () {
                                if (!selectedItems.any((want) =>
                                    want['productid'] == item['productid'])) {
                                  setState(() {
                                    selectedItems.add({
                                      'productid': item['productid'],
                                      'media_primary': {
                                        'url': item['media_primary'] != null
                                            ? (item['media_primary']
                                                as Map<String, dynamic>)['url']
                                            : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                                      },
                                      'productname': item['productname'],
                                      'price': item['price'],
                                    });
                                  });
                                }
                              },
                            ),
                          ),
                          Visibility(
                            visible: wants.any((product) =>
                                product['productid'] == item['productid']),
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
                                product['productid'] == item['productid']),
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
                                                product['productid'] ==
                                                item['productid'],
                                          );
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
                      _addWantedItems(selectedItems);
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

  _addWantedItems(List<dynamic> items) {
    setState(() {
      wants.addAll(items);
    });
  }

  _addOfferedItems(List<dynamic> items) {
    setState(() {
      offers.addAll(items);
    });
  }

  _showUserItems() {
    showMaterialModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          List<dynamic> selectedItems = [];
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
                    label: 'Select your offer(s)',
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
                              itemName: item['productname'],
                              itemPrice: item['currency'] +
                                  ((item['price'] + 0.00) as double)
                                      .toStringAsFixed(2),
                              imageUrl: item['media_primary'] != null
                                  ? (item['media_primary']
                                      as Map<String, dynamic>)['url']
                                  : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                              onTapped: () {
                                if (!selectedItems.any((want) =>
                                    want['productid'] == item['productid'])) {
                                  setState(() {
                                    selectedItems.add({
                                      'productid': item['productid'],
                                      'media_primary': {
                                        'url': item['media_primary'] != null
                                            ? (item['media_primary']
                                                as Map<String, dynamic>)['url']
                                            : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                                      },
                                      'productname': item['productname'],
                                      'price': item['price'],
                                    });
                                  });
                                }
                              },
                            ),
                          ),
                          Visibility(
                            visible: offers.any((product) =>
                                product['productid'] == item['productid']),
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
                                product['productid'] == item['productid']),
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
                                                product['productid'] ==
                                                item['productid'],
                                          );
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
                      _addOfferedItems(selectedItems);
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
