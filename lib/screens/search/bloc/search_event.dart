part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class InitializeSearch extends SearchEvent {
  final String keyword;

  InitializeSearch(this.keyword);
}

class GetProductMarkers extends SearchEvent {}

class GetNextProducts extends SearchEvent {
  final String keyword;
  final String lastProductId;
  final String startAfterVal;

  GetNextProducts({
    required this.keyword,
    required this.lastProductId,
    required this.startAfterVal,
  });
}
