part of 'store_bloc.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object> get props => [];
}

class InitializeStoreScreen extends StoreEvent {
  final String userId;

  InitializeStoreScreen(this.userId);
}
