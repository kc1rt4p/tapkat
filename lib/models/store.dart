class StoreModel {
  String? userid;
  String? display_name;
  String? photo_url;
  num? rating;

  StoreModel({
    this.userid,
    this.display_name,
    this.photo_url,
    this.rating,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        userid: json['userid'] as String?,
        display_name: json['display_name'] as String?,
        photo_url: json['photo_url'] as String?,
        rating: json['rating'] as num?,
      );

  Map<String, dynamic> toJson() => {
        "userid": this.userid,
        "display_name": this.display_name,
        "photo_url": this.photo_url,
        "rating": this.rating,
      };
}
