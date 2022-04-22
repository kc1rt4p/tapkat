part of 'wish_list_bloc.dart';

abstract class WishListState extends Equatable {
  const WishListState();

  @override
  List<Object> get props => [];
}

class WishListInitial extends WishListState {}

class WishListLoading extends WishListState {}

class WishListError extends WishListState {
  final String message;

  WishListError(this.message);
}

class WishListInitialized extends WishListState {
  final List<LikedProductModel> productList;
  final List<LikedStoreModel> storeList;
  final User user;

  WishListInitialized({
    required this.productList,
    required this.storeList,
    required this.user,
  });
}

class GetNextLikedItemsSuccess extends WishListState {
  final List<ProductModel> productList;

  GetNextLikedItemsSuccess(this.productList);
}

class GetNextFollowedStoresSuccess extends WishListState {
  final List<StoreModel> storeList;

  GetNextFollowedStoresSuccess(this.storeList);
}

class UpdateItemsWantedSuccess extends WishListState {}
