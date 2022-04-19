import 'package:tapkat/models/location.dart';

class StoreLikeModel {
  String? userid;
  String? likerid;
  String? user_image_url;
  String? username;
  String? like_date;
  LocationModel? location;
  double? distance;

  StoreLikeModel({
    this.userid,
    this.likerid,
    this.user_image_url,
    this.username,
    this.like_date,
    this.location,
    this.distance,
  });

  Map<String, dynamic> toJson() => {
        'userid': this.userid,
        'likerid': this.likerid,
        'user_image_url': this.user_image_url,
        'username': this.username,
        'like_date': this.like_date,
        'location': this.location,
        'distance': this.distance,
      };

  factory StoreLikeModel.fromJson(Map<String, dynamic> json) => StoreLikeModel(
        userid: json['userid'] as String?,
        likerid: json['likerid'] as String?,
        user_image_url: json['user_image_url'] as String?,
        username: json['username'] as String?,
        like_date: json['like_date'] as String?,
        location: json['location'] != null
            ? LocationModel.fromJson(json['location'])
            : null,
        distance: json['distance'] as double?,
      );
}

class LikedProductModel {
  String? productid;
  String? productname;
  num? price;
  String? image_url;
  String? like_date;
  LocationModel? location;
  double? distance;

  LikedProductModel({
    this.productid,
    this.productname,
    this.price,
    this.image_url,
    this.like_date,
    this.location,
    this.distance,
  });

  factory LikedProductModel.fromJson(Map<String, dynamic> json) =>
      LikedProductModel(
        productid: json['productid'] as String?,
        productname: json['productname'] as String?,
        price: json['price'] as num?,
        image_url: json['image_url'] as String?,
        like_date: json['like_date'] as String?,
        location: json['location'] != null
            ? LocationModel.fromJson(json['location'])
            : null,
        distance: json['distance'] as double?,
      );

  Map<String, dynamic> toJson() => {
        'productid': this.productid,
        'productname': this.productname,
        'price': this.price,
        'image_url': this.image_url,
        'like_date': this.like_date,
        'distance': this.distance,
      };
}
