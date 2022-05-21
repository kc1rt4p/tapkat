import 'package:tapkat/models/location.dart';

class UserModel {
  String? userid;
  String? email;
  String? display_name;
  String? phone_number;
  String? address;
  String? city;
  String? country;
  String? postcode;
  bool? verifiedByPhone;
  String? photo_url;
  String? pushalert;
  String? regtoken;
  List<String>? interests;
  List<String>? items_wanted;
  LocationModel? location;
  int? likes;
  double? rating;
  String? country_code;
  String? currency;

  String? fb_profile;
  String? ig_profile;
  String? yt_profile;
  String? tt_profile;
  String? tw_profile;
  bool? is_online;
  String? signing_method;

  UserModel({
    this.userid,
    this.email,
    this.display_name,
    this.phone_number,
    this.address,
    this.city,
    this.country,
    this.postcode,
    this.verifiedByPhone,
    this.photo_url,
    this.pushalert,
    this.regtoken,
    this.interests,
    this.items_wanted,
    this.location,
    this.likes,
    this.rating,
    this.fb_profile,
    this.ig_profile,
    this.yt_profile,
    this.tt_profile,
    this.tw_profile,
    this.is_online,
    this.country_code,
    this.currency,
    this.signing_method,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userid: json['userid'] as String?,
      email: json['email'] as String?,
      display_name: json['display_name'] as String?,
      phone_number: json['phone_number'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postcode: json['postcode'] as String?,
      verifiedByPhone: json['verifiedByPhone'] != null
          ? json['verifiedByPhone'] as bool?
          : false,
      photo_url: json['photo_url'] as String?,
      pushalert: json['pushalert'] as String?,
      regtoken: json['regtoken'] as String?,
      interests: json['interests'] != null
          ? (json['interests'] as List<dynamic>)
              .map((d) => d.toString())
              .toList()
          : null,
      items_wanted: json['items_wanted'] != null
          ? (json['items_wanted'] as List<dynamic>)
              .map((d) => d.toString())
              .toList()
          : null,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      likes: json['likes'] as int?,
      rating: json['rating'] != null ? json['rating'] + 0.00 as double? : 0.00,
      fb_profile: json['fb_profile'] as String?,
      ig_profile: json['ig_profile'] as String?,
      yt_profile: json['yt_profile'] as String?,
      tt_profile: json['tt_profile'] as String?,
      tw_profile: json['tw_profile'] as String?,
      is_online: json['is_online'] as bool?,
      country_code: json['country_code'] as String?,
      currency: json['currency'] as String?,
      signing_method: json['signing_method'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': this.userid,
      'email': this.email,
      'display_name': this.display_name,
      'phone_number': this.phone_number,
      'address': this.address,
      'city': this.city,
      'country': this.country,
      'postcode': this.postcode,
      'verifiedByPhone': this.verifiedByPhone,
      'photo_url': this.photo_url,
      'pushalert': this.pushalert,
      'regtoken': this.regtoken,
      'interests': this.interests,
      'items_wanted': this.items_wanted,
      'location': this.location,
      'likes': this.likes,
      'rating': this.rating,
      'fb_profile': this.fb_profile,
      'ig_profile': this.ig_profile,
      'yt_profile': this.yt_profile,
      'tt_profile': this.tt_profile,
      'tw_profile': this.tw_profile,
      'is_online': this.is_online,
      'country_code': this.country_code,
      'currency': this.currency,
      'signing_method': this.signing_method,
    };
  }
}
