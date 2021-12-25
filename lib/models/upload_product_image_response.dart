import 'package:tapkat/models/media_primary_model.dart';

class UploadProductImageResponseModel {
  MediaPrimaryModel? media_primary;
  List<MediaPrimaryModel>? media;

  UploadProductImageResponseModel({
    this.media,
    this.media_primary,
  });

  factory UploadProductImageResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadProductImageResponseModel(
      media_primary: MediaPrimaryModel.fromJson(json['media_primary']),
      media: (json['media'] as List<dynamic>)
          .map((m) => MediaPrimaryModel.fromJson(m))
          .toList(),
    );
  }
}
