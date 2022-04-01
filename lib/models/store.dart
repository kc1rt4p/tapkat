class StoreModel {
  String? userid;
  String? display_name;
  String? photo_url;
  num? rating;

  StoreModel({
    this.userid,
    this.display_name,
    this.photo_url,
    this.rating,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        userid: json['userid'] as String?,
        display_name: json['display_name'] as String?,
        photo_url: json['photo_url'] as String?,
        rating: json['rating'] as num?,
      );

  Map<String, dynamic> toJson() => {
        "userid": this.userid,
        "display_name": this.display_name,
        "photo_url": this.photo_url,
        "rating": this.rating,
      };
}

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
