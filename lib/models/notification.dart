import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? notificationid;
  String? userid;
  String? senderid;
  String? sendername;
  String? msg_type;
  String? barterid;
  String? title;
  String? body;
  bool? read;
  String? timestamp;

  NotificationModel({
    this.notificationid,
    this.userid,
    this.senderid,
    this.sendername,
    this.msg_type,
    this.barterid,
    this.title,
    this.body,
    this.read,
    this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        notificationid: json['notificationid'] as String?,
        userid: json['userid'] as String?,
        senderid: json['senderid'] as String?,
        sendername: json['sendername'] as String?,
        msg_type: json['msg_type'] as String?,
        barterid: json['barterid'] as String?,
        title: json['title'] as String?,
        body: json['body'] as String?,
        read: json['read'] as bool?,
        timestamp: json['timestamp'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'notificationid': this.notificationid,
        'userid': this.userid,
        'senderid': this.senderid,
        'sendername': this.sendername,
        'msg_type': this.msg_type,
        'barterid': this.barterid,
        'title': this.title,
        'body': this.body,
        'read': this.read,
        'timestamp': this.timestamp,
      };
}
