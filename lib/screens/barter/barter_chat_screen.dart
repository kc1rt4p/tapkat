import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/schemas/barter_record.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class BarterChatScreen extends StatefulWidget {
  final BarterRecord barterRecord;
  const BarterChatScreen({Key? key, required this.barterRecord})
      : super(key: key);

  @override
  _BarterChatScreenState createState() => _BarterChatScreenState();
}

class _BarterChatScreenState extends State<BarterChatScreen> {
  late BarterRecord _barterRecord;

  @override
  void initState() {
    _barterRecord = widget.barterRecord;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: ProgressHUD(
        backgroundColor: Colors.white,
        indicatorColor: kBackgroundColor,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              CustomAppBar(
                label: 'Barter Chat',
              ),
              Expanded(
                child: ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  reverse: true,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('User\'s name'),
                          Container(
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                                bottomLeft: Radius.circular(10.0),
                              ),
                            ),
                            child: Text('Message goes here'),
                          ),
                          Text(
                            timeago.format(
                              DateTime.now().subtract(
                                new Duration(minutes: 15),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User2\'s name'),
                          Container(
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                                bottomRight: Radius.circular(10.0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                    'Message goes here Message goes here Message goes here'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: kBackgroundColor,
                padding: EdgeInsets.all(12.0),
                width: double.infinity,
                height: kToolbarHeight,
                child: Row(
                  children: [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
