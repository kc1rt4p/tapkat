import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

Container buildChatItem(ChatMessageModel msg, User? currentUser) {
  return Container(
    margin: EdgeInsets.only(top: 8.0),
    child: Column(
      crossAxisAlignment: msg.userId != currentUser!.uid
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: msg.userId != currentUser.uid
                ? kBackgroundColor
                : Color(0xFFBB3F03),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
              bottomLeft: msg.userId == currentUser.uid
                  ? Radius.circular(10.0)
                  : Radius.zero,
              bottomRight: msg.userId != currentUser.uid
                  ? Radius.circular(10.0)
                  : Radius.zero,
            ),
          ),
          child: Column(
            crossAxisAlignment: msg.userId != currentUser.uid
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                msg.userId == currentUser.uid && currentUser.uid.isNotEmpty
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
