import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/repositories/auth_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/utilities/application.dart' as application;

import 'package:geolocator/geolocator.dart' as geoLocator;

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
    final _authRepo = AuthRepository();
    on<HomeEvent>((event, emit) async {
      emit(HomeLoading());

      try {
        if (event is LoadRecommendedList) {
          emit(LoadingRecommendedList());
          emit(LoadingUserList());
          emit(LoadingTrendingList());
          emit(LoadingTopStoreList());

          LocationModel _location = application.currentUserLocation ??
              application.currentUserModel!.location!;

          final recommendedList = await _productRepo.getFirstProducts(
            'reco',
            location: _location,
            sortBy: 'distance',
            radius: 5000,
            userId: application.currentUser!.uid,
            interests: application.currentUserModel != null &&
                    application.currentUserModel!.interests != null &&
                    application.currentUserModel!.interests!.isNotEmpty
                ? application.currentUserModel!.interests
                : null,
          );
          emit(LoadedRecommendedList(recommendedList));
          add(LoadTrendingList());
        }

        if (event is LoadUserList) {
          final userItems = await _productRepo.getFirstProducts(
            'user',
            userId: application.currentUser!.uid,
            sortBy: 'name',
          );
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

        // if (event is TestHeader) {
        //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        //   final devInfo = await deviceInfo.deviceInfo;
        //   final result = await _authRepo.testHeader(
        //       userid: application.currentUser!.uid,
        //       deviceid: androidInfo.androidId!,
        //       time: DateTime.now().millisecondsSinceEpoch.toString());
        // }

        if (event is LoadTrendingList) {
          LocationModel? _location;

          if (await Permission.location.isGranted &&
              await geoLocator.GeolocatorPlatform.instance
                  .isLocationServiceEnabled()) {
            final userLoc = await geoLocator.Geolocator.getCurrentPosition();
            _location = LocationModel(
              longitude: userLoc.longitude,
              latitude: userLoc.latitude,
            );
          } else {
            _location = application.currentUserLocation;
          }
          final trendingList = await _productRepo.getFirstProducts(
            'demand',
            location: _location,
            userId: application.currentUser!.uid,
            sortBy: 'distance',
          );
          emit(LoadedTrendingList(trendingList));
          add(LoadUserList());
        }

        if (event is InitializeHomeScreen) {
          add(LoadRecommendedList());
        }
      } catch (e) {
        print('ERROR ON HOME BLOC: ${e.toString()}');
      }
    });
  }
}
