import 'package:tapkat/utilities/upload_media.dart';

class ChatMessageModel {
  String? id;
  String? barterId;
  String? userId;
  String? userName;
  String? message;
  List<String>? images;
  DateTime? dateCreated;
  bool? isRead;
  List<SelectedMedia>? imagesFile;

  ChatMessageModel({
    this.id,
    this.barterId,
    this.userId,
    this.userName,
    this.message,
    this.dateCreated,
    this.isRead,
    this.images,
    this.imagesFile,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'barterId': this.barterId,
      'userId': this.userId,
      'userName': this.userName,
      'message': this.message,
      'dateCreated': this.dateCreated,
      'is_read': this.isRead ?? false,
      'images': this.images ?? [],
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    print(json);
    return ChatMessageModel(
      id: json['id'] as String?,
      barterId: json['barterId'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      message: json['message'] as String?,
      dateCreated: json['dateCreated'].toDate(),
      isRead: json['is_read'] as bool?,
      images: json['images'] != null
          ? (json['images'] as List<dynamic>)
              .map((itm) => itm as String)
              .toList()
          : null,
    );
  }
}
