import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/services/auth_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    final _authService = AuthService();
    final _productRepo = ProductRepository();
    User? _user;
    on<HomeEvent>((event, emit) async {
      emit(HomeLoading());

      try {
        _user = await _authService.getCurrentUser();

        if (event is GetUserFavorites) {
          if (_user != null) {
            final _userLikedItems =
                await _productRepo.getUserFavourites(_user!.uid);

            emit(GetUserFavoritesSuccess(_userLikedItems));
          }
        }

        if (event is LoadRecommendedList) {
          emit(LoadingRecommendedList());
          final recommendedList = await _productRepo.getFirstProducts('reco');
          emit(LoadedRecommendedList(recommendedList));
        }

        if (event is LoadUserList) {
          emit(LoadingUserList());
          final userItems =
              await _productRepo.getFirstProducts('user', _user!.uid);
          emit(LoadedUserList(userItems));
        }

        if (event is LoadTrendingList) {
          emit(LoadingTrendingList());
          final trendingList = await _productRepo.getFirstProducts('demand');
          emit(LoadedTrendingList(trendingList));
        }

        if (event is InitializeHomeScreen) {
          if (_user != null) {
            add(LoadRecommendedList());
            add(LoadTrendingList());
            add(LoadUserList());
          }
        }
      } catch (e) {
        print('ERROR ON HOME BLOC: ${e.toString()}');
      }
    });
  }
}
