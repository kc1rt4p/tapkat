import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/upload_media.dart';

class UserRepository {
  final _apiService = ApiService();

  Future<UserModel?> getUser(String userId) async {
    final result = await _apiService.get(
      url: 'users/$userId',
    );

    if (result.data['status'] != 'SUCCESS') return null;

    return UserModel.fromJson(result.data['user']);
  }

  Future<bool> addUserReview(UserReviewModel review) async {
    final result = await _apiService.post(
      url: 'users/review',
      body: {
        'psk': psk,
        ...review.toJson(),
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<bool> updateUserReview(UserReviewModel review) async {
    final result = await _apiService.patch(
      url: 'users/review/update',
      body: {
        'psk': psk,
        'userid': review.userid,
        'reviewerid': review.reviewerid,
        'rating': review.rating,
        'review': review.review,
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<bool> updateUser(UpdateUserModel user) async {
    final result = await _apiService.patch(
      url: 'users/${user.userid}',
      body: {
        'psk': "lcp9321p",
        ...user.toJson(),
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<bool> updateUserPhoto(String userId, SelectedMedia img) async {
    var formData = FormData.fromMap({
      "psk": "lcp9321p",
      'userid': userId,
    });

    final mimeType = mime(img.fileName);
    String mimee = mimeType!.split('/')[0];
    String type = mimeType.split('/')[1];

    formData.files.add(
      MapEntry(
        'media',
        MultipartFile.fromFileSync(
          img.rawPath!,
          contentType: MediaType(mimee, type),
        ),
      ),
    );

    final response = await _apiService.post(
      url: 'users/uploadpic',
      formData: formData,
    );

    return response.data['status'] == 'SUCCESS';
  }
}
