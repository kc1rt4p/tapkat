class ChatMessageModel {
  String? id;
  String? barterId;
  String? userId;
  String? userName;
  String? message;
  DateTime? dateCreated;

  ChatMessageModel({
    this.id,
    this.barterId,
    this.userId,
    this.userName,
    this.message,
    this.dateCreated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      'barterId': this.barterId,
      'userId': this.userId,
      'userName': this.userName,
      'message': this.message,
      'dateCreated': this.dateCreated,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String?,
      barterId: json['barterId'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      message: json['message'] as String?,
      dateCreated: json['dateCreated'] as DateTime?,
    );
  }
}
