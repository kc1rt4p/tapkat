import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tapkat/models/notification.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/alert_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/index.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    final _authService = AuthService();
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
    final _alertRepo = AlertRepository();

    on<ProfileEvent>((event, emit) async {
      print('profile bloc current event:: $event');
      emit(ProfileLoading());

      try {
        final _user = application.currentUser;
        if (event is InitializeProfileScreen) {
          List<ProductModel> list = [];
          UserModel? userModel;
          if (application.currentUser == null) {
            application.currentUser = _authService.currentUser!.user;
          }

          userModel = await _userRepo.getUser(application.currentUser!.uid);

          list = await _productRepo.getFirstProducts(
            'user',
            userId: application.currentUser!.uid,
            sortBy: 'distance',
          );

          if (userModel != null) {
            application.currentUserModel = userModel;
          }

          emit(ProfileScreenInitialized(
            user: _user,
            list: list,
            userModel: userModel!,
          ));
        }

        if (event is InitializeUserRatingsScreen) {
          final list1 = await _userRepo.getUserReviews(null, event.userId);
          emit(GetUserRatingsSuccess(list1));

          final list2 =
              await _productRepo.getProductRatings(userId: event.userId);
          emit(GetProductRatingsSuccess(list2));
        }

        if (event is GetUserRatings) {
          final list = await _userRepo.getUserReviews(null, event.userId);
          emit(GetUserRatingsSuccess(list));
        }

        if (event is GetRatingsForUser) {
          final list = await _userRepo.getUserReviews(event.userId, null);

          emit(GetUserRatingsSuccess(list));
        }

        if (event is GetNextUserRatings) {
          final list = await _userRepo.getNextUserReviews(
              null, event.userId, event.lastUserId, event.startAfterVal);
        }

        if (event is GetProductRatings) {
          final list =
              await _productRepo.getProductRatings(userId: event.userId);
          emit(GetProductRatingsSuccess(list));
        }

        if (event is GetNextProductRatings) {
          final list = await _productRepo.getNextRatings(
            secondaryVal: event.lastProductId,
            startAfterVal: event.startAfterVal,
            userId: event.userId,
          );
          emit(GetNextProductRatingsSuccess(list));
        }

        if (event is UpdateUserPhoto) {
          final updated =
              await _userRepo.updateUserPhoto(_user!.uid, event.photo);
          if (updated) emit(UpdateUserPhotoSuccess());
        }

        if (event is UpdateUserInfo) {
          final updated = await _userRepo.updateUser(event.user);
          application.currentUserModel =
              await _userRepo.getUser(event.user.userid!);
          if (updated) emit(UpdateUserInfoSuccess());
        }

        if (event is UpdatePassword) {
          final result = await _authService.updatePassword(
              event.currentPassword, event.newPassword);
          if (result == true) {
            emit(UpdatePasswordSuccess());
          } else {
            emit(ProfileError(result as String));
          }
        }

        if (event is UpdateUserReview) {
          final updated = await _userRepo.updateUserReview(event.review);
          if (updated) emit(UpdateUserReviewSuccess());
        }

        if (event is UpdateProductReview) {
          final updated = await _productRepo.updateProductReview(event.review);
          if (updated) emit(UpdateProductReviewSuccess());
        }

        if (event is DeleteProductReview) {
          final deleted = await _productRepo.deleteRating(event.review);
          if (deleted) emit(DeleteProductReviewSuccess());
        }

        if (event is DeleteUserReview) {
          final deleted = await _userRepo.deleteUserReview(event.review);
        }

        if (event is InitializeNotificationList) {
          final list = await _alertRepo.getNotifications();
          emit(InitializeNotificationListSuccess(list));
        }

        if (event is GetNextNotifications) {
          final list = await _alertRepo.getNotifications(event.startAfterVal);
          emit(GetNextNotificationsSuccess(list));
        }

        if (event is LinkAccToSocialMedia) {
          if (event.platform == 'facebook') {
            final existingToken = await FacebookAuth.instance.accessToken;
            if (existingToken != null) await FacebookAuth.instance.logOut();

            final LoginResult loginResult = await FacebookAuth.instance.login(
              permissions: [
                'email',
                'public_profile',
                'user_friends',
                'user_link',
              ],
              loginBehavior: LoginBehavior.nativeWithFallback,
            );
            if (loginResult.status == LoginStatus.success) {
              final userData = await FacebookAuth.instance
                  .getUserData(fields: 'email, user_link');
              emit(LinkAccToSocialMediaSuccess(
                  event.platform, userData['email']));
            } else {
              ProfileError(
                  'Unable to link account with ${event.platform.toUpperCase()}');
            }
          } else if (event.platform == 'google') {
            final auth = GoogleSignIn().currentUser == null
                ? await GoogleSignIn().signIn()
                : GoogleSignIn().currentUser;
            if (auth != null) {
              emit(LinkAccToSocialMediaSuccess(event.platform, auth.email));
            } else {
              ProfileError(
                  'Unable to link account with ${event.platform.toUpperCase()}');
            }
          }
        }
      } catch (e) {
        // FlutterLogs.logToFile(
        //     logFileName: "Home Bloc",
        //     overwrite: false,
        //     logMessage: e.toString());
        print('ERROR ON PROFILE BLOC::: ${e.toString()}');
      }
    });
  }
}
