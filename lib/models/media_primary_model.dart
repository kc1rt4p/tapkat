class MediaPrimaryModel {
  String? url;
  String? url_t;
  String? type;

  MediaPrimaryModel({
    this.url,
    this.url_t,
    this.type,
  });

  factory MediaPrimaryModel.fromJson(Map<String, dynamic> json) {
    return MediaPrimaryModel(
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      url_t: json['url_t'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': this.url,
      'type': this.type,
      'url_t': this.url_t,
    };
  }
}
