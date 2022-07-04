part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class InitializeSearch extends SearchEvent {
  final String keyword;
  final List<String>? category;
  final double distance;
  final String sortBy;
  final int? itemCount;
  final LatLng? loc;

  InitializeSearch({
    required this.keyword,
    this.category,
    required this.distance,
    required this.sortBy,
    this.itemCount,
    this.loc,
  });
}

class GetProductMarkers extends SearchEvent {}

class SearchNextProducts extends SearchEvent {
  final String keyword;
  final String? category;
  final double distance;
  final String sortBy;
  final String lastProductId;
  final dynamic startAfterVal;
  final LatLng? loc;

  SearchNextProducts({
    required this.keyword,
    this.category,
    required this.distance,
    required this.sortBy,
    required this.lastProductId,
    required this.startAfterVal,
    this.loc,
  });
}
