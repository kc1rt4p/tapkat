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
