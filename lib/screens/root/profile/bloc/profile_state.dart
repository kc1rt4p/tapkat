part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileScreenInitialized extends ProfileState {
  final User? user;
  final List<ProductModel> list;

  ProfileScreenInitialized(this.user, this.list);
}

class ProfileLoading extends ProfileState {}
