import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/services/auth_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    final _authService = AuthService();
    on<ProfileEvent>((event, emit) async {
      emit(ProfileLoading());

      if (event is InitializeProfileScreen) {
        emit(ProfileScreenInitialized(await _authService.getCurrentUser()));
      }
    });
  }
}
