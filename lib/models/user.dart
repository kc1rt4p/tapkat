class UserModel {
  String? userid;
  String? email;
  String? display_name;
  String? mobilenum;
  String? address;
  String? city;
  String? country;
  String? postcode;
  String? photo_url;

  UserModel({
    this.userid,
    this.email,
    this.display_name,
    this.mobilenum,
    this.address,
    this.city,
    this.country,
    this.postcode,
    this.photo_url,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userid: json['userid'] as String?,
      email: json['email'] as String?,
      display_name: json['display_name'] as String?,
      mobilenum: json['mobilenum'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postcode: json['postcode'] as String?,
      photo_url: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': this.userid,
      'email': this.email,
      'display_name': this.display_name,
      'mobilenum': this.mobilenum,
      'address': this.address,
      'city': this.city,
      'country': this.country,
      'postcode': this.postcode,
      'photo_url': this.photo_url,
    };
  }
}
