part of 'root_bloc.dart';

abstract class RootEvent extends Equatable {
  const RootEvent();

  @override
  List<Object> get props => [];
}

class MoveTab extends RootEvent {
  final int index;

  MoveTab(this.index);
}

class UpdateUserToken extends RootEvent {}

class DeleteRegistrationTokens extends RootEvent {
  final List<String> ids;

  DeleteRegistrationTokens(this.ids);
}
