part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class InitializeSearch extends SearchEvent {
  final String keyword;
  final String? category;

  InitializeSearch(this.keyword, this.category);
}

class GetProductMarkers extends SearchEvent {}

class SearchNextProducts extends SearchEvent {
  final String keyword;
  final String lastProductId;
  final String startAfterVal;

  SearchNextProducts({
    required this.keyword,
    required this.lastProductId,
    required this.startAfterVal,
  });
}
