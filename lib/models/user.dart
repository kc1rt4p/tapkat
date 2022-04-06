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
  String? photo_url;
  String? pushtoken;
  String? regtoken;
  List<String>? interests;
  LocationModel? location;

  UserModel({
    this.userid,
    this.email,
    this.display_name,
    this.phone_number,
    this.address,
    this.city,
    this.country,
    this.postcode,
    this.photo_url,
    this.pushtoken,
    this.regtoken,
    this.interests,
    this.location,
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
      photo_url: json['photo_url'] as String?,
      pushtoken: json['pushtoken'] as String?,
      regtoken: json['regtoken'] as String?,
      interests: json['interests'] != null
          ? (json['interests'] as List<dynamic>)
              .map((d) => d.toString())
              .toList()
          : null,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
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
      'photo_url': this.photo_url,
      'pushtoken': this.pushtoken,
      'regtoken': this.regtoken,
      'interests': this.interests,
      'location': this.location,
    };
  }
}
