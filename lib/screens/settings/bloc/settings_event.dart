part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class GetLocalizations extends SettingsEvent {}

class SetDefaultCountry extends SettingsEvent {
  final LocalizationModel country;

  SetDefaultCountry(this.country);
}
