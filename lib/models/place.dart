import 'package:google_maps_flutter/google_maps_flutter.dart';

class FFPlace {
  const FFPlace({
    this.latLng = const LatLng(0.0, 0.0),
    this.name = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.zipCode = '',
  });

  final LatLng? latLng;
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  @override
  String toString() => '''FFPlace(
        latLng: $latLng,
        name: $name,
        address: $address,
        city: $city,
        state: $state,
        country: $country,
        zipCode: $zipCode,
      )''';

  @override
  int get hashCode => latLng.hashCode;

  @override
  bool operator ==(other) =>
      other is FFPlace &&
      latLng == other.latLng &&
      name == name &&
      address == address &&
      city == city &&
      state == state &&
      country == country &&
      zipCode == zipCode;
}
