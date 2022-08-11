class ProviderData {
  String? displayName;
  String? email;
  String? phoneNumber;
  String? photoURL;
  String? providerId;
  String? uid;

  ProviderData({
    this.displayName,
    this.email,
    this.phoneNumber,
    this.photoURL,
    this.providerId,
    this.uid,
  });

  factory ProviderData.fromJson(Map<String, String> json) {
    return ProviderData(
      displayName: json['displayName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      providerId: json['providerId'],
      uid: json['uid'],
    );
  }
}
