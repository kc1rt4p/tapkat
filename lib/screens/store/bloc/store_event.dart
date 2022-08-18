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

class GetFirstTopStores extends StoreEvent {
  final int itemCount;
  final String sortBy;
  final double radius;
  final LocationModel? loc;

  GetFirstTopStores({
    this.itemCount = 10,
    required this.sortBy,
    required this.radius,
    this.loc,
  });
}

class GetNextTopStores extends StoreEvent {
  final int? itemCount;
  final String sortBy;
  final double radius;
  final LocationModel? loc;
  final num startAfterVal;
  final String userId;

  GetNextTopStores({
    this.itemCount,
    required this.sortBy,
    required this.radius,
    this.loc,
    required this.startAfterVal,
    required this.userId,
  });
}

class EditUserLike extends StoreEvent {
  final UserModel user;
  final int likeCount;

  EditUserLike({
    required this.user,
    required this.likeCount,
  });
}
