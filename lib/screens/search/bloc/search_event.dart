part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class InitializeSearch extends SearchEvent {
  final String keyword;
  final String? category;
  final int distance;
  final String sortBy;

  InitializeSearch({
    required this.keyword,
    this.category,
    required this.distance,
    required this.sortBy,
  });
}

class GetProductMarkers extends SearchEvent {}

class SearchNextProducts extends SearchEvent {
  final String keyword;
  final String? category;
  final int distance;
  final String sortBy;
  final String lastProductId;
  final String startAfterVal;

  SearchNextProducts({
    required this.keyword,
    this.category,
    required this.distance,
    required this.sortBy,
    required this.lastProductId,
    required this.startAfterVal,
  });
}
