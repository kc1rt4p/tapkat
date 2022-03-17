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

class ProfileLoading extends ProfileState {}

class UpdateUserInfoSuccess extends ProfileState {}
