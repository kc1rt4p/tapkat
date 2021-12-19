class MediaPrimaryModel {
  String? url;
  String? type;

  MediaPrimaryModel({
    this.url,
    this.type,
  });

  factory MediaPrimaryModel.fromJson(Map<String, dynamic> json) {
    return MediaPrimaryModel(
      url: json['url'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': this.url,
      'type': this.type,
    };
  }
}
