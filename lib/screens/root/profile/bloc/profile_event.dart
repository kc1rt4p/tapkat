part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class InitializeProfileScreen extends ProfileEvent {}

class UpdateUserPhoto extends ProfileEvent {
  final SelectedMedia photo;

  UpdateUserPhoto(this.photo);
}

class UpdateUserInfo extends ProfileEvent {
  final UpdateUserModel user;

  UpdateUserInfo(this.user);
}

class GetUserRatings extends ProfileEvent {
  final String userId;

  GetUserRatings(this.userId);
}

class GetProductRatings extends ProfileEvent {
  final String userId;

  GetProductRatings(this.userId);
}

class GetNextProductRatings extends ProfileEvent {
  final String userId;
  final String lastProductId;
  final String startAfterVal;

  GetNextProductRatings({
    required this.userId,
    required this.lastProductId,
    required this.startAfterVal,
  });
}

class GetNextUserRatings extends ProfileEvent {
  final String userId;
  final String lastUserId;
  final String startAfterVal;

  GetNextUserRatings({
    required this.userId,
    required this.lastUserId,
    required this.startAfterVal,
  });
}
