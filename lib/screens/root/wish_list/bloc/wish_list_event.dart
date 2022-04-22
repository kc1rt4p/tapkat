part of 'wish_list_bloc.dart';

abstract class WishListEvent extends Equatable {
  const WishListEvent();

  @override
  List<Object> get props => [];
}

class InitializeWishListScreen extends WishListEvent {}

class GetNextLikedItems extends WishListEvent {
  final String lastProductId;
  final String lastProductDate;

  GetNextLikedItems(
      {required this.lastProductId, required this.lastProductDate});
}

class GetNextFollowedStores extends WishListEvent {
  final String lastStoreId;
  final String lastStoreDate;

  GetNextFollowedStores(
      {required this.lastStoreId, required this.lastStoreDate});
}

class UpdateItemsWanted extends WishListEvent {
  final List<String> wants;

  UpdateItemsWanted(this.wants);
}
