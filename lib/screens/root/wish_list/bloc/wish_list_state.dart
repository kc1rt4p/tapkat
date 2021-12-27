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
  final List<ProductModel> list;
  final User user;

  WishListInitialized(this.list, this.user);
}
