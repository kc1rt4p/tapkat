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

class GetNextRatings extends ProfileEvent {
  final String userId;
  final String lastProductId;
  final double startAfterVal;

  GetNextRatings({
    required this.userId,
    required this.lastProductId,
    required this.startAfterVal,
  });
}
