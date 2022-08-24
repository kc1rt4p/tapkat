part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeScreenInitialized extends HomeState {}

class LoadedUserList extends HomeState {
  final List<ProductModel> yourItems;

  LoadedUserList(this.yourItems);
}

class LoadProductsInCategoriesSuccess extends HomeState {
  final List<Map<String, dynamic>> list;

  LoadProductsInCategoriesSuccess(this.list);
}

class LoadedTrendingList extends HomeState {
  final List<ProductModel> trending;

  LoadedTrendingList(this.trending);
}

class LoadTopStoresSuccess extends HomeState {
  final List<TopStoreModel> topStoreItems;

  LoadTopStoresSuccess(this.topStoreItems);
}

class LoadingTopStoreList extends HomeState {}

class LoadedRecommendedList extends HomeState {
  final List<ProductModel> recommended;

  LoadedRecommendedList(this.recommended);
}

class HomeLoading extends HomeState {}

class LoadingFreeList extends HomeState {}

class GetUserFavoritesSuccess extends HomeState {
  final List<ProductModel> list;

  GetUserFavoritesSuccess(this.list);
}

class LoadedFreeList extends HomeState {
  final List<ProductModel> list;

  LoadedFreeList(this.list);
}

class LoadingRecommendedList extends HomeState {}

class LoadingTrendingList extends HomeState {}

class LoadingUserList extends HomeState {}

class TestHeaderSuccess extends HomeState {
  final String msg;

  TestHeaderSuccess(this.msg);
}

class BarterExists extends HomeState {
  final ProductModel product1;
  final ProductModel product2;
  BarterExists({
    required this.product1,
    required this.product2,
  });
}

class BarterDoesNotExist extends HomeState {
  final ProductModel product1;
  final ProductModel product2;

  BarterDoesNotExist({
    required this.product1,
    required this.product2,
  });
}
