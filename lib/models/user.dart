class UserModel {
  String? userid;
  String? email;
  String? firstname;
  String? middlename;
  String? lastname;
  String? logintype;
  String? address;
  String? city;
  String? country;
  String? postcode;
  String? mobilecc;
  String? mobilenum;
  String? photo_url;

  UserModel({
    this.userid,
    this.email,
    this.firstname,
    this.middlename,
    this.lastname,
    this.logintype,
    this.address,
    this.city,
    this.country,
    this.postcode,
    this.mobilecc,
    this.mobilenum,
    this.photo_url,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userid: json['userid'] as String?,
      email: json['email'] as String?,
      firstname: json['firstname'] as String?,
      middlename: json['middlename'] as String?,
      lastname: json['lastname'] as String?,
      logintype: json['logintype'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postcode: json['postcode'] as String?,
      mobilecc: json['mobilecc'] as String?,
      mobilenum: json['mobilenum'] as String?,
      photo_url: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': this.userid,
      'email': this.email,
      'firstname': this.firstname,
      'middlename': this.middlename,
      'lastname': this.lastname,
      'logintype': this.logintype,
      'address': this.address,
      'city': this.city,
      'country': this.country,
      'postcode': this.postcode,
      'mobilecc': this.mobilecc,
      'mobilenum': this.mobilenum,
      'photo_url': this.photo_url,
    };
  }
}
