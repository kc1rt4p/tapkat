import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'root_event.dart';
part 'root_state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final _userRepo = UserRepository();
  RootBloc() : super(RootInitial()) {
    on<RootEvent>((event, emit) async {
      emit(RootInitial());
      if (event is MoveTab) emit(MoveToTab(event.index));

      if (event is UpdateUserToken) {
        final updated = await _userRepo.updateUserFCMToken();
        final updatedSettings = await _userRepo.updatePushAlert(true);
        if (updated && updatedSettings) {
          emit(UpdateUserTokenSuccess());
          application.currentUserModel =
              await _userRepo.getUser(application.currentUser!.uid);
        }
      }
    });
  }
}
