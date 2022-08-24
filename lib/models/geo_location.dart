class GeoLocationModel {
  double? lng;
  double? lat;

  GeoLocationModel({
    this.lng,
    this.lat,
  });

  factory GeoLocationModel.fromJson(Map<String, dynamic> json) =>
      GeoLocationModel(
        lat: json['lat'] as double?,
        lng: json['lng'] as double?,
      );

  Map<String, dynamic> toJson() => {
        'lat': this.lat,
        'lng': this.lng,
      };
}
