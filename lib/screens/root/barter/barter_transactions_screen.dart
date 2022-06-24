import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tapkat/utilities/application.dart' as application;

class BarterTransactionsScreen extends StatefulWidget {
  const BarterTransactionsScreen({Key? key}) : super(key: key);

  @override
  _BarterTransactionsScreenState createState() =>
      _BarterTransactionsScreenState();
}

class _BarterTransactionsScreenState extends State<BarterTransactionsScreen> {
  late BarterBloc _barterBloc;
  List<BarterRecordModel> byYouList = [];
  List<BarterRecordModel> fromOthersList = [];

  List<BarterRecordModel> openInitiatedList = [];
  List<BarterRecordModel> completedInitiatedList = [];

  List<BarterRecordModel> openOffersList = [];
  List<BarterRecordModel> completedOffersList = [];

  StreamSubscription<List<BarterRecordModel>>? _byYouStream;
  StreamSubscription<List<BarterRecordModel>>? _fromOthersStream;

  String _view = 'open';

  @override
  void initState() {
    application.currentScreen = 'Barter Transactions Screen';
    _barterBloc = BlocProvider.of<BarterBloc>(context);
    super.initState();

    _barterBloc.add(InitializeBarterTransactions());
  }

  @override
  void dispose() {
    _byYouStream?.cancel();
    _byYouStream = null;
    _fromOthersStream?.cancel();
    _fromOthersStream = null;
    // _barterBloc.close();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      backgroundColor: Colors.white,
      indicatorColor: kBackgroundColor,
      child: Container(
        color: Color(0xFFEBFBFF),
        child: Column(
          children: [
            CustomAppBar(
              label: 'Your Barters',
              hideBack: true,
            ),
            SizedBox(height: 5.0),
            ToggleSwitch(
              activeBgColor: [kBackgroundColor],
              initialLabelIndex: _view == 'open' ? 0 : 1,
              minWidth: SizeConfig.screenWidth * 0.4,
              minHeight: 25.0,
              borderColor: [Color(0xFFEBFBFF)],
              totalSwitches: 2,
              customTextStyles: [
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.textScaleFactor * 15,
                  color: Colors.white,
                ),
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.textScaleFactor * 15,
                  color: Colors.white,
                ),
              ],
              labels: [
                'OPEN',
                'COMPLETED',
              ],
              onToggle: (index) {
                setState(() {
                  _view = index == 0 ? 'open' : 'completed';
                });
              },
            ),
            Expanded(
              child: BlocListener(
                bloc: _barterBloc,
                listener: (context, state) {
                  if (state is BarterLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is DeleteBarterSuccess) {
                    _barterBloc.add(InitializeBarterTransactions());
                  }

                  if (state is BarterTransactionsInitialized) {
                    if (_byYouStream != null) {
                      _byYouStream!.cancel();
                    }
                    _byYouStream = state.byYouStream.listen((list) {
                      setState(() {
                        if (list.isNotEmpty) {
                          byYouList = list;
                          openInitiatedList = byYouList
                              .where((br) => br.dealStatus != 'completed')
                              .toList();
                          completedInitiatedList = byYouList
                              .where((br) => br.dealStatus == 'completed')
                              .toList();
                        } else {
                          byYouList.clear();
                        }

                        byYouList
                            .sort((a, b) => b.dealDate!.compareTo(a.dealDate!));
                        openInitiatedList
                            .sort((a, b) => b.dealDate!.compareTo(a.dealDate!));
                        completedInitiatedList
                            .sort((a, b) => b.dealDate!.compareTo(a.dealDate!));
                      });
                      // List<BarterRecordModel> _byYou = [];
                      // List<BarterRecordModel> _fromOthers = [];

                      // list.forEach((barterRecord) {
                      //   if (barterRecord.userid1Role == 'sender') {
                      //     _byYou.add(barterRecord);
                      //   } else {
                      //     _fromOthers.add(barterRecord);
                      //   }
                      // });

                      // setState(() {
                      //   if (_byYou.isNotEmpty)
                      //     byYouList.addAll(_byYou);
                      //   else
                      //     byYouList.clear();

                      //   if (_fromOthers.isNotEmpty)
                      //     fromOthersList.addAll(_fromOthers);
                      //   else
                      //     fromOthersList.clear();
                      // });
                    });
                    if (_fromOthersStream != null) {
                      _fromOthersStream!.cancel();
                    }
                    _fromOthersStream = state.fromOthersStream.listen((list) {
                      setState(() {
                        if (list.isNotEmpty) {
                          fromOthersList = list
                              .where((barterRecord) =>
                                  barterRecord.dealStatus != 'new')
                              .toList();
                          openOffersList = fromOthersList
                              .where((br) => br.dealStatus != 'completed')
                              .toList();
                          completedOffersList = fromOthersList
                              .where((br) => br.dealStatus == 'completed')
                              .toList();
                        } else {
                          fromOthersList.clear();
                        }

                        fromOthersList
                            .sort((a, b) => b.dealDate!.compareTo(a.dealDate!));
                        openOffersList
                            .sort((a, b) => b.dealDate!.compareTo(a.dealDate!));
                        completedOffersList
                            .sort((a, b) => b.dealDate!.compareTo(a.dealDate!));
                      });
                      // List<BarterRecordModel> _byYou = [];
                      // List<BarterRecordModel> _fromOthers = [];

                      // list.forEach((barterRecord) {
                      //   if (barterRecord.dealStatus != 'new') {
                      //     if (barterRecord.userid1Role == 'sender') {
                      //       _byYou.add(barterRecord);
                      //     } else {
                      //       _fromOthers.add(barterRecord);
                      //     }
                      //   }
                      // });

                      // setState(() {
                      //   if (_byYou.isNotEmpty)
                      //     byYouList.addAll(_byYou);
                      //   else
                      //     byYouList.clear();

                      //   if (_fromOthers.isNotEmpty)
                      //     fromOthersList.addAll(_fromOthers);
                      //   else
                      //     fromOthersList.clear();
                      // });
                    });
                  }

                  if (state is BarterError) {
                    print('BARTER ERROR: ${state.message}');
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.0),
                      Text(
                        'Barters You Initiated',
                        style: Style.subtitle2.copyWith(
                          color: kBackgroundColor,
                          fontSize: SizeConfig.textScaleFactor * 17,
                        ),
                      ),
                      SizedBox(height: 6.0),
                      Expanded(
                        child: (_view == 'open'
                                    ? openInitiatedList
                                    : completedInitiatedList)
                                .isNotEmpty
                            ? _buildListContainer(
                                _view == 'open'
                                    ? openInitiatedList
                                    : completedInitiatedList,
                                'For')
                            : Center(
                                child: Text('No barters found'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Offers from Other Users',
                            style: Style.subtitle2.copyWith(
                              color: kBackgroundColor,
                              fontSize: SizeConfig.textScaleFactor * 17,
                            ),
                          ),
                          SizedBox(height: 6.0),
                          Expanded(
                            child: (_view == 'open'
                                        ? openOffersList
                                        : completedOffersList)
                                    .isNotEmpty
                                ? _buildListContainer(
                                    _view == 'open'
                                        ? openOffersList
                                        : completedOffersList,
                                    'From')
                                : Center(
                                    child: Text('No offers found'),
                                  ),
                          ),
                        ],
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

  Container _buildListContainer(List<BarterRecordModel> list, String prefix) {
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: list.map(
            (barter) {
              var name = prefix.toLowerCase() == 'from'
                  ? barter.userid1Name!
                  : barter.userid2Name!;
              if (name.length > 10) {
                name = name.substring(0, 10) + '...';
              }
              return FittedBox(
                child: Container(
                  margin: EdgeInsets.only(right: SizeConfig.screenWidth * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: '$prefix '),
                            TextSpan(
                              text: name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Stack(
                        children: [
                          BarterListItem(
                            hideDistance: true,
                            showRating: false,
                            product: ProductModel(
                              productid: barter.u2P1Id!,
                              productname: barter.u2P1Name ?? '',
                              price: barter.u2P1Price != null
                                  ? barter.u2P1Price!
                                  : 0.00,
                              mediaPrimary: MediaPrimaryModel(
                                type: 'image',
                                url_t: barter.u2P1Image,
                                url: barter.u2P1Image,
                              ),
                            ),
                            hideLikeBtn: true,
                            onTapped: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BarterScreen(
                                    barterRecord: barter,
                                  ),
                                ),
                              );

                              _barterBloc.add(InitializeBarterTransactions());
                            },
                            status: barter.dealStatus,
                          ),
                          Visibility(
                            visible: [
                              'new',
                              'completed',
                              'rejected',
                              'withdrawn'
                            ].contains(barter.dealStatus),
                            child: Positioned(
                              top: 5,
                              right: 5,
                              child: InkWell(
                                onTap: () =>
                                    _onDeletebarter('Barter', barter.barterId!),
                                child: Container(
                                  padding: EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: SizeConfig.textScaleFactor * 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: application.unreadBarterMessages
                                .any((msg) => msg.barterId == barter.barterId),
                            child: Positioned(
                              top: 30,
                              right: 5,
                              child: Container(
                                padding: EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: Icon(
                                  Icons.chat_bubble,
                                  color: Colors.white,
                                  size: SizeConfig.textScaleFactor * 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      barter.dealDate != null
                          ? Container(
                              width: SizeConfig.screenHeight * 0.17,
                              child: Text(
                                timeago.format(barter.dealDate!),
                                style: Style.subtitle2.copyWith(
                                    fontSize: SizeConfig.textScaleFactor * 9),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  _onDeletebarter(String type, String id) {
    DialogMessage.show(
      context,
      title: 'Delete $type',
      message: 'Are you sure you want to delete this $type?',
      buttonText: 'Yes',
      firstButtonClicked: () => _barterBloc.add(DeleteBarter(id)),
      secondButtonText: 'No',
      hideClose: true,
    );
  }
}
