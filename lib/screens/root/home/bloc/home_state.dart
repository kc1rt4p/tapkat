part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeScreenInitialized extends HomeState {
  final List<ProductModel> recommended;
  final List<ProductModel> trending;
  final List<ProductModel> yourItems;

  HomeScreenInitialized({
    required this.recommended,
    required this.trending,
    required this.yourItems,
  });
}

class HomeLoading extends HomeState {}

class GetUserFavoritesSuccess extends HomeState {
  final List<ProductModel> list;

  GetUserFavoritesSuccess(this.list);
}
