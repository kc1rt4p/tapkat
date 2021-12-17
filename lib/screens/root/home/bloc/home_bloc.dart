import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/services/http/api_calls.dart';
import 'package:tapkat/utilities/helper.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    final _authService = AuthService();
    on<HomeEvent>((event, emit) async {
      emit(HomeLoading());
      if (event is InitializeHomeScreen) {
        final _user = await _authService.getCurrentUser();
        if (_user != null) {
          final recommendedCallResult =
              await getRecommendedProductsCall(userid: _user.uid);
          final recommendedList =
              (getJsonField(recommendedCallResult, r'''$.products''')
                          ?.toList() ??
                      [])
                  .take(20)
                  .toList();

          final trendingCallResult =
              await getProductsInDemandCall(userid: _user.uid);
          final trendingList =
              (getJsonField(trendingCallResult, r'''$.products''')?.toList() ??
                      [])
                  .take(20)
                  .toList();

          final userProductsCallResult =
              await getUserProductsCall(userid: _user.uid);
          final userProductList =
              (getJsonField(userProductsCallResult, r'''$.products''')
                          ?.toList() ??
                      [])
                  .take(20)
                  .toList();

          emit(
            HomeScreenInitialized(
              recommended: recommendedList,
              trending: trendingList,
              yourItems: userProductList,
            ),
          );
        }
      }
    });
  }
}
