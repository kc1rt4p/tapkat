part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class UpdateUserPhotoSuccess extends ProfileState {}

class ProfileScreenInitialized extends ProfileState {
  final User? user;
  final List<ProductModel> list;
  final UserModel userModel;

  ProfileScreenInitialized({
    required this.user,
    required this.list,
    required this.userModel,
  });
}

class UpdatePasswordSuccess extends ProfileState {}

class ProfileLoading extends ProfileState {}

class UpdateUserInfoSuccess extends ProfileState {}

class GetUserRatingsSuccess extends ProfileState {
  final List<UserReviewModel> list;

  GetUserRatingsSuccess(this.list);
}

class GetProductRatingsSuccess extends ProfileState {
  final List<ProductReviewModel> list;

  GetProductRatingsSuccess(this.list);
}

class GetNextProductRatingsSuccess extends ProfileState {
  final List<ProductReviewModel> list;

  GetNextProductRatingsSuccess(this.list);
}

class GetNextUserRatingsSuccess extends ProfileState {
  final List<UserReviewModel> list;

  GetNextUserRatingsSuccess(this.list);
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
