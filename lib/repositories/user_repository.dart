import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';
import 'package:tapkat/models/localization.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/utilities/application.dart' as application;

class UserRepository {
  final _apiService = ApiService();
  final usersRef = FirebaseFirestore.instance.collection('users');
  final _firebaseAuth = FirebaseAuth.instance;

  Future<UserModel?> getUser(String userId) async {
    final result = await _apiService.get(
      url: 'users/$userId',
    );

    if (result.data['status'] != 'SUCCESS') return null;

    return UserModel.fromJson(result.data['user']);
  }

  Stream<bool> streamUserOnlineStatus(String userId) {
    return usersRef.doc(userId).snapshots().map((query) {
      if (query.exists) {
        final data = query.data();
        if (data != null) {
          final user = UserModel.fromJson(data);
          return user.is_online ?? false;
        }
      }

      return false;
    });
    // return barterRef.doc(barterId).collection('products').snapshots().map(
    //     (query) => query.docs
    //         .map((doc) => BarterProductModel.fromJson(doc.data()))
    //         .toList());
  }

  Future<bool> checkIfPhoneExists(String phoneNumber) async {
    final querySnapshot =
        await usersRef.where('phone_number', isEqualTo: phoneNumber).get();
    return querySnapshot.docs.length > 0;
  }

  Future<bool> updateUserFCMToken() async {
    final updated = await _apiService
        .patch(url: 'users/${application.currentUser!.uid}', body: {
      'userid': application.currentUser!.uid,
      'regtoken': await FirebaseMessaging.instance.getToken(),
      'deviceid': application.deviceId,
    });

    return updated.data['status'] == 'SUCCESS';
  }

  Future<bool> updateDefaultCountry(LocalizationModel localization) async {
    final updated = await _apiService
        .patch(url: 'users/${application.currentUser!.uid}', body: {
      'userid': application.currentUser!.uid,
      'country_code': localization.country_code,
      'currency': localization.currency,
    });

    return updated.data['status'] == 'SUCCESS';
  }

  Future<bool> deleteRegistrationToken(String id) async {
    final deleted = await _apiService.delete(url: 'users/regtoken', body: {
      'userid': id,
      'deviceid': application.deviceId,
    });

    return deleted.data['status'] == 'SUCCESS';
  }

  Future<bool> updatePushAlert(bool enable) async {
    final updated = await _apiService
        .patch(url: 'users/${application.currentUser!.uid}', body: {
      'userid': application.currentUser!.uid,
      'pushalert': enable ? 'Y' : 'N',
    });

    return updated.data['status'] == 'SUCCESS';
  }

  Future<bool> updateUserOnlineStatus(bool isOnline) async {
    final updated = await _apiService
        .patch(url: 'users/${application.currentUser!.uid}', body: {
      'userid': application.currentUser!.uid,
      'is_online': isOnline,
    });

    return updated.data['status'] == 'SUCCESS';
  }

  Future<bool> addUserReview(UserReviewModel review) async {
    final result = await _apiService.post(
      url: 'users/review',
      body: {
        ...review.toJson(),
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<bool> deleteUserReview(UserReviewModel review) async {
    final result = await _apiService.delete(
      url: 'users/review/delete',
      body: {
        'userid': review.userid,
        'reviewerid': review.reviewerid,
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<List<UserReviewModel>> getUserReviews(
      String? userid, String? reviewerid) async {
    var _body = {
      'sortby': 'date',
      'sortdirection': 'descending',
      'productCount': 10,
    };
    if (userid != null) _body.addAll({'userid': userid});
    if (reviewerid != null) _body.addAll({'reviewerid': reviewerid});
    final result = await _apiService.post(
      url: 'users/review/searchfirst',
      body: _body,
    );

    if (result.data['status'] != 'SUCCESS') return [];

    return (result.data['products'] as List<dynamic>)
        .map((json) => UserReviewModel.fromJson(json))
        .toList();
  }

  Future<List<StoreModel>> getFirstTopStores() async {
    final result = await _apiService.post(
      url: 'users/top/searchfirst',
      body: {
        "psk": psk,
        "itemcount": productCount,
      },
    );

    if (result.data['status'] != 'SUCCESS') return [];

    return (result.data['users'] as List<dynamic>)
        .map((json) => StoreModel.fromJson(json))
        .toList();
  }

  Future<List<LikedStoreModel>> getUserLikedStores(String likerId) async {
    final result = await _apiService.post(
      url: 'users/storelikes/searchfirst',
      body: {
        'likerid': likerId,
        'itemcount': productCount,
      },
    );

    if (result.data['status'] != 'SUCCESS') return [];

    return (result.data['like_list'] as List<dynamic>)
        .map((json) => LikedStoreModel.fromJson(json))
        .toList();
  }

  Future<List<StoreModel>> getNextUserLikedStores({
    required String likerId,
    required String startAfterVal,
    required String lastStoreId,
  }) async {
    final result = await _apiService.post(
      url: 'users/storelikes/searchfirst',
      body: {
        'likerid': likerId,
        'itemcount': productCount,
        'startafterval': startAfterVal,
        'userid': lastStoreId,
      },
    );

    if (result.data['status'] != 'SUCCESS') return [];

    return (result.data['users'] as List<dynamic>)
        .map((json) => StoreModel.fromJson(json))
        .toList();
  }

  Future<List<StoreModel>> getNextTopStores(
      String lastUserId, num lastUserRating) async {
    final result = await _apiService.post(
      url: 'users/top/searchset',
      body: {
        "psk": psk,
        "itemcount": productCount,
        "startafterval": lastUserRating,
        "userId": lastUserId,
      },
    );

    if (result.data['status'] != 'SUCCESS') return [];

    return (result.data['users'] as List<dynamic>)
        .map((json) => StoreModel.fromJson(json))
        .toList();
  }

  Future<bool> addLikeToStore({
    required UserModel user,
    required String likerId,
    required int val,
  }) async {
    final result = await _apiService.post(
      url: 'users/store/like',
      body: {
        "psk": psk,
        "userid": user.userid,
        "username": user.display_name,
        "user_image_url": user.photo_url,
        "likerid": likerId,
        "like": val,
      },
    );

    return (result.data['status'] == 'SUCCESS');
  }

  Future<List<UserReviewModel>> getNextUserReviews(
    String? userid,
    String? reviewerid,
    String lastuserid,
    String startAfterVal,
  ) async {
    var _body = {
      'sortby': 'date',
      'sortdirection': 'descending',
      'productCount': 10,
      'startafterval': startAfterVal,
      'secondaryval': lastuserid,
    };
    if (userid != null) _body.addAll({'userid': userid});
    if (reviewerid != null) _body.addAll({'reviewerid': reviewerid});
    final result = await _apiService.post(
      url: 'users/review/searchfirst',
      body: _body,
    );

    if (result.data['status'] != 'SUCCESS') return [];

    return (result.data['products'] as List<dynamic>)
        .map((json) => UserReviewModel.fromJson(json))
        .toList();
  }

  Future<UserReviewModel?> getUserReview(
      String userId, String reviewerId) async {
    final result = await _apiService.post(
      url: 'users/review/get',
      body: {
        'userid': userId,
        'reviewerid': reviewerId,
      },
    );

    if (result.data['status'] == 'SUCCESS')
      return UserReviewModel.fromJson(result.data['products']);

    return null;
  }

  Future<bool> updateUserReview(UserReviewModel review) async {
    final result = await _apiService.patch(
      url: 'users/review/update',
      body: {
        ...review.toJson(),
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<bool> updateUser(UpdateUserModel user) async {
    final result = await _apiService.patch(
      url: 'users/${user.userid}',
      body: {
        ...user.toJson(),
      },
    );

    return result.data['status'] == 'SUCCESS';
  }

  Future<bool> updateUserWantedItems(List<String> wants) async {
    final result = await _apiService.patch(
      url: 'users/${application.currentUser!.uid}',
      body: {
        'userid': application.currentUser!.uid,
        'items_wanted': wants,
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

  Future<void> sendOtp(
      String phoneNumber,
      Duration timeOut,
      PhoneVerificationFailed phoneVerificationFailed,
      PhoneVerificationCompleted phoneVerificationCompleted,
      PhoneCodeSent phoneCodeSent,
      PhoneCodeAutoRetrievalTimeout autoRetrievalTimeout,
      int? forceResendingToken) async {
    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeOut,
      verificationCompleted: phoneVerificationCompleted,
      verificationFailed: phoneVerificationFailed,
      codeSent: phoneCodeSent,
      codeAutoRetrievalTimeout: autoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<UserCredential> verifyAndLogin(
      String verificationId, String smsCode) async {
    AuthCredential authCredential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);

    return await _firebaseAuth.signInWithCredential(authCredential);
  }

  Future<User?> getFirebaseUser() async {
    return _firebaseAuth.currentUser;
  }
}
