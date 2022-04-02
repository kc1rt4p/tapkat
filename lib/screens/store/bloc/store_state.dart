part of 'store_bloc.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object> get props => [];
}

class StoreInitial extends StoreState {}

class InitializedStoreScreen extends StoreState {
  final UserModel user;
  final Stream<QuerySnapshot<Map<String, dynamic>>> storeLikeStream;

  InitializedStoreScreen({
    required this.user,
    required this.storeLikeStream,
  });
}

class LoadingStore extends StoreState {}

class StoreError extends StoreState {
  final String message;

  StoreError(this.message);
}

class GetFirstTopStoresSuccess extends StoreState {
  final List<StoreModel> list;

  GetFirstTopStoresSuccess(this.list);
}

class GetNextTopStoresSuccess extends StoreState {
  final List<StoreModel> list;

  GetNextTopStoresSuccess(
    this.list,
  );
}

class EditUserLikeSuccess extends StoreState {}
