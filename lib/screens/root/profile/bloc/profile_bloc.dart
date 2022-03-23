import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/utilities/upload_media.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    final _authService = AuthService();
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
    on<ProfileEvent>((event, emit) async {
      emit(ProfileLoading());

      final _user = await _authService.getCurrentUser();
      if (event is InitializeProfileScreen) {
        if (_user != null) {
          final userModel = await _userRepo.getUser(_user.uid);
          final list = await _productRepo.getFirstProducts('user', _user.uid);

          emit(ProfileScreenInitialized(
            user: _user,
            list: list,
            userModel: userModel!,
          ));
        }
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
        final list = await _productRepo.getProductRatings(userId: event.userId);
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
        if (updated) emit(UpdateUserInfoSuccess());
      }
    });
  }
}
