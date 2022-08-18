import 'package:tapkat/models/geo_location.dart';

class StoreModel {
  String? userid;
  String? display_name;
  String? photo_url;
  double? rating;
  int? likes;
  GeoLocationModel? geo_location;
  double? distance;

  StoreModel({
    this.userid,
    this.display_name,
    this.photo_url,
    this.rating,
    this.likes,
    this.geo_location,
    this.distance,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    print(']-rating-> ${json['rating']}');
    return StoreModel(
      userid: json['userid'],
      display_name: json['display_name'],
      photo_url: json['photo_url'],
      rating: json['rating'].runtimeType == int
          ? json['rating'] + 0.0 as double
          : json['rating'],
      likes: json['likes'],
      geo_location: GeoLocationModel.fromJson(json['geo_location']),
      distance: json['distance'].runtimeType == int
          ? json['distance'] + 0.0 as double
          : json['distance'],
    );
  }

  Map<String, dynamic> toJson() => {
        "userid": this.userid,
        "display_name": this.display_name,
        "photo_url": this.photo_url,
        "rating": this.rating,
        "likes": this.likes,
        "geo_location":
            this.geo_location != null ? this.geo_location!.toJson() : null,
        "distance": this.distance,
      };
}
