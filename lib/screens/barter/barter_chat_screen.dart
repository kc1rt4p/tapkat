import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/screens/barter/bloc/barter_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class BarterChatScreen extends StatefulWidget {
  final String barterId;
  const BarterChatScreen({Key? key, required this.barterId}) : super(key: key);

  @override
  _BarterChatScreenState createState() => _BarterChatScreenState();
}

class _BarterChatScreenState extends State<BarterChatScreen> {
  final _messageTextController = TextEditingController();
  late AuthBloc _authBloc;
  late String _barterId;
  final _barterBloc = BarterBloc();
  List<ChatMessageModel> _messages = [];
  StreamSubscription<List<ChatMessageModel?>>? _barterChatStreamSub;
  User? _user;

  @override
  void initState() {
    _barterId = widget.barterId;
    _barterBloc.add(InitializeBarterChat(_barterId));
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
                      setState(() {
                        _user = state.user;
                      });

                      _barterChatStreamSub =
                          state.barterChatStream.listen((list) {
                        print('list streamed: ${list.length} items');
                        if (list.isNotEmpty) {
                          setState(() {
                            _messages = list;
                            print(_messages.first.dateCreated);
                          });
                        }
                      });
                    }

                    if (state is BarterError) {
                      print('BARTER ERROR ===== ${state.message}');
                    }
                  },
                  child: ListView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    reverse: true,
                    children: _messages.reversed
                        .map((msg) => _buildChatItem(msg))
                        .toList(),
                  ),
                ),
              ),
              Container(
                color: kBackgroundColor,
                padding: EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 10.0,
                ),
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
  }

  Container _buildChatItem(ChatMessageModel msg) {
    return Container(
      margin: EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: msg.userId != _user!.uid
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: msg.userId != _user!.uid
                  ? kBackgroundColor
                  : Color(0xFFBB3F03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
                bottomLeft: msg.userId == _user!.uid
                    ? Radius.circular(10.0)
                    : Radius.zero,
                bottomRight: msg.userId != _user!.uid
                    ? Radius.circular(10.0)
                    : Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: msg.userId != _user!.uid
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  msg.userId == _user!.uid && _user!.uid.isNotEmpty
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

  @override
  void dispose() {
    _barterChatStreamSub?.cancel();
    super.dispose();
  }
}
