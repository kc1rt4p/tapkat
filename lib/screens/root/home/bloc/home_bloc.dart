import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/auth_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';

import 'package:geolocator/geolocator.dart' as geoLocator;

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    final _authService = AuthService();
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
    final _authRepo = AuthRepository();
    User? _user;
    UserModel? _userModel;
    on<HomeEvent>((event, emit) async {
      emit(HomeLoading());

      try {
        _user = await _authService.getCurrentUser();
        _userModel = _authService.currentUserModel ??
            await _userRepo.getUser(_user!.uid);

        if (event is LoadRecommendedList) {
          emit(LoadingRecommendedList());
          emit(LoadingUserList());
          emit(LoadingTrendingList());
          emit(LoadingTopStoreList());

          final recommendedList = await _productRepo.getFirstProducts(
            'reco',
            _user!.uid,
            null,
            null,
            _userModel != null &&
                    _userModel!.interests != null &&
                    _userModel!.interests!.isNotEmpty
                ? _userModel!.interests
                : null,
          );
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

        if (event is TestHeader) {
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          final devInfo = await deviceInfo.deviceInfo;
          final result = await _authRepo.testHeader(
              userid: _user!.uid,
              deviceid: androidInfo.androidId!,
              time: DateTime.now().millisecondsSinceEpoch.toString());
        }

        if (event is LoadTrendingList) {
          final _userModel = await _userRepo.getUser(_user!.uid);
          LocationModel? _location;

          if (await Permission.location.isGranted &&
              await geoLocator.GeolocatorPlatform.instance
                  .isLocationServiceEnabled()) {
            final userLoc = await geoLocator.Geolocator.getCurrentPosition();
            _location = LocationModel(
              longitude: userLoc.longitude,
              latitude: userLoc.latitude,
            );
          }
          final trendingList = await _productRepo.getFirstProducts(
            'demand',
            _user!.uid,
            _location != null
                ? _location.latitude
                : _userModel!.location != null
                    ? _userModel.location!.latitude
                    : null,
            _location != null
                ? _location.longitude
                : _userModel!.location != null
                    ? _userModel.location!.longitude
                    : null,
          );
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
