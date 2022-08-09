import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/repositories/barter_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    final _productRepo = ProductRepository();
    final _userRepo = UserRepository();
    final _barterRepo = BarterRepository();
    on<HomeEvent>((event, emit) async {
      emit(HomeLoading());

      try {
        if (event is LoadRecommendedList) {
          LocationModel _location = application.currentUserLocation ??
              application.currentUserModel!.location ??
              LocationModel(latitude: 0, longitude: 0);

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
          emit(LoadedUserList(
              userItems.where((item) => item.status != 'completed').toList()));
          add(LoadProductsInCategories());
        }

        if (event is LoadTopStores) {
          emit(LoadingRecommendedList());
          emit(LoadingUserList());
          emit(LoadingTrendingList());
          emit(LoadingTopStoreList());
          emit(LoadingFreeList());

          final topStoreItems = await _userRepo.getFirstTopStores();
          emit(LoadTopStoresSuccess(topStoreItems));
          // add(LoadProductsInCategories());
          add(LoadRecommendedList());
        }

        if (event is LoadProductsInCategories) {
          final list = await _productRepo.getAllCategoryProducts();
          emit(LoadProductsInCategoriesSuccess(list));
        }

        if (event is CheckBarter) {
          final barterId = application.currentUser!.uid +
              event.product1.userid! +
              event.product1.productid!;
          final barterRecord = await _barterRepo.getBarterRecord(barterId);

          if (barterRecord != null) {
            if (barterRecord.deletedFor != null &&
                barterRecord.deletedFor!
                    .contains(application.currentUser!.uid)) {
              emit(BarterDoesNotExist(
                product1: event.product1,
                product2: event.product2,
              ));
              return;
            }
            emit(BarterExists(
              product1: event.product1,
              product2: event.product2,
            ));
          } else {
            emit(BarterDoesNotExist(
              product1: event.product1,
              product2: event.product2,
            ));
          }
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
          LocationModel _location = application.currentUserLocation ??
              application.currentUserModel!.location ??
              LocationModel(latitude: 0, longitude: 0);
          final trendingList = await _productRepo.getFirstProducts(
            'demand',
            location: _location,
            userId: application.currentUser!.uid,
            sortBy: 'distance',
          );

          emit(LoadedTrendingList(trendingList));
          add(LoadFreeList());
        }

        if (event is LoadFreeList) {
          emit(LoadingFreeList());
          LocationModel _location = application.currentUserLocation ??
              application.currentUserModel!.location ??
              LocationModel(latitude: 0, longitude: 0);
          final list = await _productRepo.getFirstProducts(
            'free',
            location: _location,
            userId: application.currentUser!.uid,
            sortBy: 'distance',
          );
          emit(LoadedFreeList(list));
          add(LoadUserList());
        }

        if (event is InitializeHomeScreen) {
          // add(LoadRecommendedList());
          add(LoadTopStores());
        }
      } catch (e) {
        print('ERROR ON HOME BLOC: ${e.toString()}');
        FlutterLogs.logToFile(
            logFileName: "Home Bloc",
            overwrite: false,
            logMessage: e.toString());
      }
    });
  }
}
