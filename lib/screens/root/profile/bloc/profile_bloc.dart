import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    final _authService = AuthService();
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
    on<ProfileEvent>((event, emit) async {
      emit(ProfileLoading());

      if (event is InitializeProfileScreen) {
        final _user = await _authService.getCurrentUser();
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
    });
  }
}
