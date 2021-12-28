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
                    if (state is BarterLoading) {
                      ProgressHUD.of(context)!.show();
                    } else {
                      ProgressHUD.of(context)!.dismiss();
                    }

                    if (state is BarterTransactionsInitialized) {
                      setState(() {
                        byYouList = state.byYouList;
                        fromOthersList = state.fromOthersList;
                      });
                    }
                  },
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
                                'Barters You Initiated',
                                style: Style.subtitle2
                                    .copyWith(color: kBackgroundColor),
                              ),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: byYouList.map((barter) {
                                        print(barter.toJson());
                                        return Container(
                                          margin: EdgeInsets.only(right: 12.0),
                                          child: BarterListItem(
                                            hideLikeBtn: true,
                                            itemName: barter.u1P1Name ?? '',
                                            itemPrice: barter.u1P1Price != null
                                                ? barter.u1P1Price!
                                                    .toStringAsFixed(2)
                                                : '0.00',
                                            imageUrl: barter.u1P1Image ?? '',
                                            onTapped: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BarterScreen(
                                                  barterRecord: barter,
                                                ),
                                              ),
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
                              style: Style.subtitle2
                                  .copyWith(color: kBackgroundColor),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: fromOthersList.map((barter) {
                                      print(barter.toJson());
                                      return Container(
                                        margin: EdgeInsets.only(right: 12.0),
                                        child: BarterListItem(
                                          hideLikeBtn: true,
                                          itemName: barter.u1P1Name ?? '',
                                          itemPrice: barter.u1P1Price != null
                                              ? barter.u1P1Price!
                                                  .toStringAsFixed(2)
                                              : '0.00',
                                          imageUrl: barter.u1P1Image ?? '',
                                          onTapped: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BarterScreen(
                                                barterRecord: barter,
                                              ),
                                            ),
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
