import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/user.dart';

class UpdateUserModel {
  String? userid;
  String? display_name;
  String? firstname;
  String? middlename;
  String? lastname;
  String? type;
  String? email;
  String? country;
  String? country_code;
  String? currency;
  String? city;
  String? address;
  String? postcode;
  String? phone_number;
  bool? verifiedByPhone;
  LocationModel? location;
  List<String>? interests;
  List<String>? items_wanted;
  String? fb_profile;
  String? ig_profile;
  String? yt_profile;
  String? tt_profile;
  String? tw_profile;
  String? signin_method;

  UpdateUserModel({
    this.userid,
    this.display_name,
    this.firstname,
    this.middlename,
    this.lastname,
    this.type,
    this.email,
    this.country,
    this.country_code,
    this.currency,
    this.city,
    this.address,
    this.postcode,
    this.verifiedByPhone,
    this.phone_number,
    this.location,
    this.interests,
    this.items_wanted,
    this.fb_profile,
    this.ig_profile,
    this.yt_profile,
    this.tt_profile,
    this.tw_profile,
    this.signin_method,
  });

  factory UpdateUserModel.fromUser(UserModel user) => UpdateUserModel(
        userid: user.userid,
        display_name: user.display_name,
        email: user.email,
        country: user.country,
        country_code: user.country_code,
        currency: user.currency,
        city: user.city,
        address: user.address,
        postcode: user.postcode,
        verifiedByPhone: user.verifiedByPhone,
        phone_number: user.phone_number,
        location: user.location,
        interests: user.interests,
        items_wanted: user.items_wanted,
        fb_profile: user.fb_profile,
        ig_profile: user.ig_profile,
        yt_profile: user.yt_profile,
        tt_profile: user.tt_profile,
        tw_profile: user.tw_profile,
      );

  Map<String, dynamic> toJson() {
    return {
      "userid": this.userid,
      "display_name": this.display_name,
      "firstname": this.firstname,
      "middlename": this.middlename,
      "lastname": this.lastname,
      "type": this.type,
      "email": this.email,
      "country": this.country,
      "country_code": this.country_code,
      "currency": this.currency,
      "city": this.city,
      "address": this.address,
      "postcode": this.postcode,
      'verifiedByPhone': this.verifiedByPhone,
      "phone_number": this.phone_number,
      "location": this.location != null ? this.location!.toJson() : null,
      'interests': this.interests,
      'items_wanted': this.items_wanted,
      'fb_profile': this.fb_profile,
      'ig_profile': this.ig_profile,
      'yt_profile': this.yt_profile,
      'tt_profile': this.tt_profile,
      'tw_profile': this.tw_profile,
      'signin_method': this.signin_method,
    };
  }
}
