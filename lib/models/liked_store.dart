class LikedStoreModel {
  String? userid;
  String? username;
  String? user_image_url;
  String? like_date;

  LikedStoreModel({
    this.userid,
    this.username,
    this.user_image_url,
    this.like_date,
  });

  Map<String, dynamic> toJson() => {
        'userid': this.userid,
        'username': this.username,
        'user_image_url': this.user_image_url,
        'like_date': this.like_date,
      };

  factory LikedStoreModel.fromJson(Map<String, dynamic> json) =>
      LikedStoreModel(
        userid: json['userid'] as String?,
        username: json['username'] as String?,
        user_image_url: json['user_image_url'] as String?,
        like_date: json['like_date'] as String?,
      );
}
