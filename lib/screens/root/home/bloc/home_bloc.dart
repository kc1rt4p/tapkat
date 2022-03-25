import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    final _authService = AuthService();
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
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
          emit(LoadingUserList());
          emit(LoadingTrendingList());
          emit(LoadingTopStoreList());
          final recommendedList =
              await _productRepo.getFirstProducts('reco', _user!.uid);
          emit(LoadedRecommendedList(recommendedList));
          add(LoadTrendingList());
        }

        if (event is LoadUserList) {
          final userItems =
              await _productRepo.getFirstProducts('user', _user!.uid);
          emit(LoadedUserList(userItems));
          add(LoadTopStores());
        }

        if (event is LoadTopStores) {
          final topStoreItems = await _userRepo.getFirstTopStores();
          emit(LoadTopStoresSuccess(topStoreItems));
          add(LoadProductsInCategories());
        }

        if (event is LoadProductsInCategories) {
          final list = await _productRepo.getAllCategoryProducts();
          emit(LoadProductsInCategoriesSuccess(list));
        }

        if (event is LoadTrendingList) {
          final _userModel = await _userRepo.getUser(_user!.uid);
          final trendingList = await _productRepo.getFirstProducts(
              'demand',
              _user!.uid,
              _userModel!.location!.latitude,
              _userModel.location!.longitude);
          emit(LoadedTrendingList(trendingList));
          add(LoadUserList());
        }

        if (event is InitializeHomeScreen) {
          if (_user != null) {
            add(LoadRecommendedList());
          }
        }
      } catch (e) {
        print('ERROR ON HOME BLOC: ${e.toString()}');
      }
    });
  }
}
