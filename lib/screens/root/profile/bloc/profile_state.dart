part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileScreenInitialized extends ProfileState {
  final User? user;

  ProfileScreenInitialized(this.user);
}

class ProfileLoading extends ProfileState {}
