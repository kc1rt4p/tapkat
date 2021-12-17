import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/services/http/api_calls.dart';
import 'package:tapkat/utilities/helper.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchEvent>((event, emit) async {
      emit(SearchLoading());
      if (event is InitializeSearch) {
        final searchCallResult =
            await searchProductsCall(searchString: event.keyword);

        final searchResults =
            (getJsonField(searchCallResult, r'''$.products''')?.toList() ?? [])
                .take(50)
                .toList();
        print('search result: $searchResults');
        emit(SearchSuccess(searchResults));
      }

      if (event is GetProductMarkers) {
        emit(GetProductMarkersSuccess(queryProductMarkersRecord(limit: 20)));
      }
    });
  }
}
