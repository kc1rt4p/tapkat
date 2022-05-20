import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/models/localization.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/reference_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final _refRepo = ReferenceRepository();
  final _userRepo = UserRepository();
  SettingsBloc() : super(SettingsInitial()) {
    on<SettingsEvent>((event, emit) async {
      emit(SettingsLoading());

      try {
        if (event is GetLocalizations) {
          final list = await _refRepo.getLocalizations();
          emit(GetLocalizationsSuccess(list));
        }

        if (event is SetDefaultCountry) {
          final updated = await _userRepo.updateDefaultCountry(event.country);
          if (updated) {
            final user = await _userRepo.getUser(application.currentUser!.uid);
            application.currentUserModel = user;
            emit(SetDefaultCountrySuccess(user!));
          }
        }
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    });
  }
}
