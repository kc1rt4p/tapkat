part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class InitializeHomeScreen extends HomeEvent {}

class GetUserFavorites extends HomeEvent {}

class LoadRecommendedList extends HomeEvent {}

class LoadTrendingList extends HomeEvent {}

class LoadUserList extends HomeEvent {}

class LoadProductsInCategories extends HomeEvent {}

class LoadTopStores extends HomeEvent {}

class TestHeader extends HomeEvent {}

class LoadFreeList extends HomeEvent {}
