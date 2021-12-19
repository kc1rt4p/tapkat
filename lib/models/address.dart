import 'location.dart';

class AddressModel {
  String? postCode;
  String? city;
  String? address;
  String? country;
  LocationModel? location;

  AddressModel({
    this.postCode,
    this.city,
    this.address,
    this.country,
    this.location,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      postCode: json['postCode'],
      city: json['city'],
      address: json['address'],
      country: json['country'],
      location: LocationModel.fromJson(json['location']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postCode': this.postCode,
      'city': this.city,
      'address': this.address,
      'country': this.country,
      'location': this.location,
    };
  }
}
