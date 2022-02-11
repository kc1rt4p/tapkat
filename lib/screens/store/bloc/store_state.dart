part of 'store_bloc.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object> get props => [];
}

class StoreInitial extends StoreState {}

class InitializedStoreScreen extends StoreState {
  final UserModel user;

  InitializedStoreScreen(this.user);
}

class LoadingStore extends StoreState {}

class StoreError extends StoreState {
  final String message;

  StoreError(this.message);
}
