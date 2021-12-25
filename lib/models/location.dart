class LocationModel {
  num? longitude;
  num? latitude;

  LocationModel({
    this.longitude,
    this.latitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['_latitude'],
      longitude: json['_longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_longitude': this.longitude,
      '_latitude': this.latitude,
    };
  }
}
