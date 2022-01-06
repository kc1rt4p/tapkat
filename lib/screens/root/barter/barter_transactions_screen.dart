import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
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

  @override
  void initState() {
    _barterBloc.add(InitializeBarterTransactions());
    super.initState();
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
                    print('barter trans current state: $state');
                    if (state is BarterLoading) {
                      ProgressHUD.of(context)!.show();
                    } else {
                      ProgressHUD.of(context)!.dismiss();
                    }

                    if (state is DeleteBarterSuccess) {
                      _barterBloc.add(InitializeBarterTransactions());
                    }

                    if (state is BarterTransactionsInitialized) {
                      setState(() {
                        byYouList = state.byYouList;
                        fromOthersList = state.fromOthersList;
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
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: byYouList.map((barter) {
                                        final barteringWith = barter.userid2 !=
                                                    null &&
                                                barter.userid2!.length > 10
                                            ? barter.userid2!.substring(0, 10) +
                                                '...'
                                            : barter.userid2!;
                                        return GestureDetector(
                                          onLongPress: () => _barterBloc.add(
                                              DeleteBarter(barter.barterId!)),
                                          child: Container(
                                            margin:
                                                EdgeInsets.only(right: 12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      color: Colors.black,
                                                    ),
                                                    children: [
                                                      TextSpan(text: 'For '),
                                                      TextSpan(
                                                        text: barteringWith,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                                BarterListItem(
                                                  hideLikeBtn: true,
                                                  itemName:
                                                      barter.u1P1Name ?? '',
                                                  itemPrice: barter.u1P1Price !=
                                                          null
                                                      ? barter.u1P1Price!
                                                          .toStringAsFixed(2)
                                                      : '0.00',
                                                  imageUrl:
                                                      barter.u1P1Image ?? '',
                                                  onTapped: () =>
                                                      Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          BarterScreen(
                                                        barterRecord: barter,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                barter.dealDate != null
                                                    ? Container(
                                                        width: 160.0,
                                                        child: Text(
                                                          timeago.format(
                                                              barter.dealDate!),
                                                          style: Style.subtitle2
                                                              .copyWith(
                                                                  fontSize:
                                                                      12.0),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      )
                                                    : Container(),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            SizedBox(height: 10.0),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: fromOthersList.map((barter) {
                                      final barteringWith = barter.userid1 !=
                                                  null &&
                                              barter.userid1!.length > 10
                                          ? barter.userid1!.substring(0, 10) +
                                              '...'
                                          : barter.userid1!;

                                      return GestureDetector(
                                        onLongPress: () => _barterBloc.add(
                                            DeleteBarter(barter.barterId!)),
                                        child: Container(
                                          margin: EdgeInsets.only(right: 12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: Colors.black,
                                                  ),
                                                  children: [
                                                    TextSpan(text: 'From '),
                                                    TextSpan(
                                                      text: barteringWith,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 8.0),
                                              BarterListItem(
                                                hideLikeBtn: true,
                                                itemName: barter.u1P1Name ?? '',
                                                itemPrice:
                                                    barter.u1P1Price != null
                                                        ? barter.u1P1Price!
                                                            .toStringAsFixed(2)
                                                        : '0.00',
                                                imageUrl:
                                                    barter.u1P1Image ?? '',
                                                onTapped: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BarterScreen(
                                                      barterRecord: barter,
                                                      fromOtherUser: true,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              barter.dealDate != null
                                                  ? Container(
                                                      width: 160.0,
                                                      child: Text(
                                                        timeago.format(
                                                            barter.dealDate!),
                                                        style: Style.subtitle2
                                                            .copyWith(
                                                                fontSize: 12.0),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    )
                                                  : Container(),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
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
}
