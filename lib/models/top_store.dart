import 'package:tapkat/models/geo_location.dart';

class TopStoreModel {
  String? userid;
  String? display_name;
  String? photo_url;
  int? likes;
  double? rating;
  GeoLocationModel? geo_location;
  double? distance;

  TopStoreModel({
    this.userid,
    this.display_name,
    this.photo_url,
    this.likes,
    this.rating,
    this.geo_location,
    this.distance,
  });

  factory TopStoreModel.fromJson(Map<String, dynamic> json) => TopStoreModel(
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
