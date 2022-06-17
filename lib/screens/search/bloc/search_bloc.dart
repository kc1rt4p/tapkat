import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    final _productRepo = ProductRepository();
    on<SearchEvent>((event, emit) async {
      emit(SearchLoading());

      try {
        if (event is InitializeSearch) {
          final result = await _productRepo.searchProducts(
            event.keyword.isNotEmpty ? event.keyword.trim().split(" ") : [],
            sortBy: event.sortBy.toLowerCase() == 'name'
                ? 'productname'
                : event.sortBy,
            radius: event.distance,
            category: event.category,
            location: application.currentUserLocation ??
                application.currentUserModel!.location ??
                LocationModel(latitude: 0, longitude: 0),
            itemCount: event.itemCount ?? 10,
          );
          print('search result count: ${result.length}');

          emit(SearchSuccess(result));
        }

        if (event is SearchNextProducts) {
          final list = await _productRepo.searchProducts(
            event.keyword.split(" "),
            sortBy: event.sortBy == 'name' ? 'productname' : event.sortBy,
            radius: event.distance,
            lastProductId: event.lastProductId,
            startAfterVal: event.startAfterVal,
            location: application.currentUserLocation ??
                application.currentUserModel!.location ??
                LocationModel(latitude: 0, longitude: 0),
          );

          emit(SearchNextProductsSuccess(list));
        }

        if (event is GetProductMarkers) {
          emit(GetProductMarkersSuccess(queryProductMarkersRecord(limit: 20)));
        }
      } catch (e) {
        FlutterLogs.logToFile(
            logFileName: "Home Bloc",
            overwrite: false,
            logMessage: e.toString());
      }
    });
  }
}
