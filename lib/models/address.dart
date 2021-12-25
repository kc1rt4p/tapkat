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
      postCode: json['postcode'],
      city: json['city'],
      address: json['address'],
      country: json['country'],
      location: json['location'] != null && json['location'] != ''
          ? LocationModel.fromJson(json['location'] as dynamic)
          : null,
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
