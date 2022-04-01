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

class GetFirstTopStores extends StoreEvent {}

class GetNextTopStores extends StoreEvent {
  final String lastUserId;
  final num lastUserRating;

  GetNextTopStores({required this.lastUserId, required this.lastUserRating});
}

class EditUserLike extends StoreEvent {
  final UserModel user;
  final int likeCount;

  EditUserLike({
    required this.user,
    required this.likeCount,
  });
}
