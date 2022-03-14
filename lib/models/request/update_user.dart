import 'package:tapkat/models/location.dart';

class UpdateUserModel {
  String? userid;
  String? display_name;
  String? firstname;
  String? middlename;
  String? lastname;
  String? type;
  String? email;
  String? country;
  String? city;
  String? address;
  String? postcode;
  String? phone_number;
  LocationModel? location;

  UpdateUserModel({
    this.userid,
    this.display_name,
    this.firstname,
    this.middlename,
    this.lastname,
    this.type,
    this.email,
    this.country,
    this.city,
    this.address,
    this.postcode,
    this.phone_number,
    this.location,
  });

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
      "city": this.city,
      "address": this.address,
      "postcode": this.postcode,
      "phone_number": this.phone_number,
      "location": this.location != null ? this.location!.toJson() : null,
    };
  }
}
