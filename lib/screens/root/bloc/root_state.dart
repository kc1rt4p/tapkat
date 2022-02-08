part of 'root_bloc.dart';

abstract class RootState extends Equatable {
  const RootState();

  @override
  List<Object> get props => [];
}

class RootInitial extends RootState {}

class MoveToTab extends RootState {
  final int index;

  MoveToTab(this.index);
}
