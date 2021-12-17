part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeScreenInitialized extends HomeState {
  final List<dynamic> recommended;
  final List<dynamic> trending;
  final List<dynamic> yourItems;

  HomeScreenInitialized({
    required this.recommended,
    required this.trending,
    required this.yourItems,
  });
}

class HomeLoading extends HomeState {}
