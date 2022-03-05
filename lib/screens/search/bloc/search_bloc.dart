import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/schemas/product_markers_record.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    final _productRepo = ProductRepository();
    on<SearchEvent>((event, emit) async {
      emit(SearchLoading());
      if (event is InitializeSearch) {
        final result =
            await _productRepo.searchProducts(event.keyword.split(" "));
        print('search result count: ${result.length}');

        emit(SearchSuccess(result));
      }

      if (event is GetNextProducts) {
        final list = await _productRepo.searchProducts(
          event.keyword.split(" "),
          lastProductId: event.lastProductId,
          startAfterVal: event.startAfterVal,
        );

        emit(GetNextProductsSuccess(list));
      }

      if (event is GetProductMarkers) {
        emit(GetProductMarkersSuccess(queryProductMarkersRecord(limit: 20)));
      }
    });
  }
}
