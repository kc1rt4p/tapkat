import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class BarterTransactionsScreen extends StatefulWidget {
  const BarterTransactionsScreen({Key? key}) : super(key: key);

  @override
  _BarterTransactionsScreenState createState() =>
      _BarterTransactionsScreenState();
}

class _BarterTransactionsScreenState extends State<BarterTransactionsScreen> {
  final _barterBloc = BarterBloc();
  List<BarterRecordModel> byYouList = [];
  List<BarterRecordModel> fromOthersList = [];

  StreamSubscription<List<BarterRecordModel>>? _byYouStream;
  StreamSubscription<List<BarterRecordModel>>? _fromOthersStream;

  @override
  void initState() {
    _barterBloc.add(InitializeBarterTransactions());
    super.initState();
  }

  @override
  void dispose() {
    _byYouStream?.cancel();
    _byYouStream = null;
    _fromOthersStream?.cancel();
    _fromOthersStream = null;
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
    return Scaffold(
      body: ProgressHUD(
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
                      _byYouStream = state.byYouStream.listen((list) {
                        setState(() {
                          if (list.isNotEmpty) {
                            byYouList.addAll(list);
                          } else {
                            byYouList.clear();
                          }
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

                      _fromOthersStream = state.fromOthersStream.listen((list) {
                        setState(() {
                          if (list.isNotEmpty) {
                            fromOthersList = list
                                .where((barterRecord) =>
                                    barterRecord.dealStatus != 'new')
                                .toList();
                          } else {
                            fromOthersList.clear();
                          }
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10.0),
                              Text(
                                'Barters You Initiated',
                                style: Style.subtitle2.copyWith(
                                  color: kBackgroundColor,
                                  fontSize: 20.0,
                                ),
                              ),
                              SizedBox(height: 10.0),
                              Expanded(
                                child: byYouList.isNotEmpty
                                    ? SingleChildScrollView(
                                        child: Container(
                                            width: double.infinity,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: byYouList.map(
                                                  (barter) {
                                                    var name =
                                                        barter.userid2Name !=
                                                                    null &&
                                                                barter
                                                                    .userid2Name!
                                                                    .isNotEmpty
                                                            ? barter
                                                                .userid2Name!
                                                            : barter.userid2!;
                                                    if (name.length > 10) {
                                                      name = name.substring(
                                                              0, 10) +
                                                          '...';
                                                    }
                                                    return Stack(
                                                      children: [
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  right: 10.0),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              RichText(
                                                                text: TextSpan(
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                  children: [
                                                                    TextSpan(
                                                                        text:
                                                                            'For '),
                                                                    TextSpan(
                                                                      text:
                                                                          name,
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 8.0),
                                                              BarterListItem(
                                                                hideLikeBtn:
                                                                    true,
                                                                itemName: barter
                                                                        .u2P1Name ??
                                                                    '',
                                                                itemPrice: barter
                                                                            .u2P1Price !=
                                                                        null
                                                                    ? barter
                                                                        .u2P1Price!
                                                                        .toStringAsFixed(
                                                                            2)
                                                                    : '0.00',
                                                                imageUrl: barter
                                                                        .u2P1Image ??
                                                                    '',
                                                                onTapped:
                                                                    () async {
                                                                  await Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              BarterScreen(
                                                                        barterRecord:
                                                                            barter,
                                                                      ),
                                                                    ),
                                                                  );

                                                                  // _barterBloc
                                                                  //     .add(
                                                                  //   InitializeBarterTransactions(),
                                                                  // );
                                                                },
                                                              ),
                                                              barter.dealDate !=
                                                                      null
                                                                  ? Container(
                                                                      width:
                                                                          160.0,
                                                                      child:
                                                                          Text(
                                                                        timeago.format(
                                                                            barter.dealDate!),
                                                                        style: Style
                                                                            .subtitle2
                                                                            .copyWith(fontSize: 12.0),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                            ],
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: (SizeConfig
                                                                      .screenHeight *
                                                                  0.26) *
                                                              0.555,
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        5.0),
                                                            color:
                                                                kBackgroundColor,
                                                            width: SizeConfig
                                                                    .screenWidth *
                                                                0.4,
                                                            child: Text(
                                                              (barter.dealStatus ??
                                                                      '')
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontSize: 14.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 30.0,
                                                          right: 20,
                                                          child: InkWell(
                                                            onTap: () =>
                                                                _onDeletebarter(
                                                                    'Barter',
                                                                    barter
                                                                        .barterId!),
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(3.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                              child: Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ).toList(),
                                              ),
                                            )),
                                      )
                                    : Center(
                                        child: Text('No barters found'),
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
                          children: [
                            Text(
                              'Offers from Other Users',
                              style: Style.subtitle2.copyWith(
                                color: kBackgroundColor,
                                fontSize: 20.0,
                              ),
                            ),
                            Expanded(
                              child: fromOthersList.isNotEmpty
                                  ? SingleChildScrollView(
                                      child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: fromOthersList.map(
                                                (barter) {
                                                  var name =
                                                      barter.userid1Name !=
                                                                  null &&
                                                              barter
                                                                  .userid1Name!
                                                                  .isNotEmpty
                                                          ? barter.userid1Name!
                                                          : barter.userid1!;

                                                  if (name.length > 10) {
                                                    name =
                                                        name.substring(0, 10) +
                                                            '...';
                                                  }
                                                  return Stack(
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            right: 10.0),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            RichText(
                                                              text: TextSpan(
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                children: [
                                                                  TextSpan(
                                                                      text:
                                                                          'From '),
                                                                  TextSpan(
                                                                    text: name,
                                                                    style:
                                                                        TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: 8.0),
                                                            BarterListItem(
                                                                hideLikeBtn:
                                                                    true,
                                                                itemName: barter
                                                                        .u2P1Name ??
                                                                    '',
                                                                itemPrice: barter
                                                                            .u2P1Price !=
                                                                        null
                                                                    ? barter
                                                                        .u2P1Price!
                                                                        .toStringAsFixed(
                                                                            2)
                                                                    : '0.00',
                                                                imageUrl: barter
                                                                        .u2P1Image ??
                                                                    '',
                                                                onTapped:
                                                                    () async {
                                                                  await Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              BarterScreen(
                                                                        barterRecord:
                                                                            barter,
                                                                        // fromOtherUser:
                                                                        //     true,
                                                                      ),
                                                                    ),
                                                                  );

                                                                  // _barterBloc.add(
                                                                  //     InitializeBarterTransactions());
                                                                }),
                                                            barter.dealDate !=
                                                                    null
                                                                ? Container(
                                                                    width:
                                                                        160.0,
                                                                    child: Text(
                                                                      timeago.format(
                                                                          barter
                                                                              .dealDate!),
                                                                      style: Style
                                                                          .subtitle2
                                                                          .copyWith(
                                                                              fontSize: 12.0),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                          ],
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: (SizeConfig
                                                                    .screenHeight *
                                                                0.26) *
                                                            0.555,
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      5.0),
                                                          color:
                                                              kBackgroundColor,
                                                          width: SizeConfig
                                                                  .screenWidth *
                                                              0.4,
                                                          child: Text(
                                                            (barter.dealStatus !=
                                                                            null &&
                                                                        barter.dealStatus ==
                                                                            'submitted'
                                                                    ? 'NEW'
                                                                    : barter.dealStatus ??
                                                                        '')
                                                                .toUpperCase(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize: 14.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 30.0,
                                                        right: 20,
                                                        child: InkWell(
                                                          onTap: () =>
                                                              _onDeletebarter(
                                                                  'Offer',
                                                                  barter
                                                                      .barterId!),
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    3.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Colors.red,
                                                            ),
                                                            child: Icon(
                                                              Icons.close,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ).toList(),
                                            ),
                                          )),
                                    )
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
