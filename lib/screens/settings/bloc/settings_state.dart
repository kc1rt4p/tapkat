part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class GetLocalizationsSuccess extends SettingsState {
  final List<LocalizationModel> list;

  GetLocalizationsSuccess(this.list);
}

class SetDefaultCountrySuccess extends SettingsState {
  final UserModel user;

  SetDefaultCountrySuccess(this.user);
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}
