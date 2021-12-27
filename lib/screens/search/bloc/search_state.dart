part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchSuccess extends SearchState {
  final List<ProductModel> searchResults;

  SearchSuccess(this.searchResults);
}

class SearchLoading extends SearchState {}

class SearchInitialized extends SearchState {
  final List<dynamic> searchResults;

  SearchInitialized(this.searchResults);
}

class GetProductMarkersSuccess extends SearchState {
  final Stream<List<ProductMarkersRecord?>> productMarkers;

  GetProductMarkersSuccess(this.productMarkers);
}
