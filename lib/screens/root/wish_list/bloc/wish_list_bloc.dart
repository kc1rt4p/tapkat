import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:tapkat/models/liked_store.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';

part 'wish_list_event.dart';
part 'wish_list_state.dart';

class WishListBloc extends Bloc<WishListEvent, WishListState> {
  WishListBloc() : super(WishListInitial()) {
    User? _user;
    final _productRepo = ProductRepository();
    final _authService = AuthService();
    final _userRepo = UserRepository();

    on<WishListEvent>((event, emit) async {
      try {
        _user = await _authService.getCurrentUser();

        if (event is InitializeWishListScreen) {
          emit(WishListLoading());
          final productList = await _productRepo.getUserFavourites(_user!.uid);
          final storeList = await _userRepo.getUserLikedStores(_user!.uid);
          if (_user != null) {
            emit(WishListInitialized(
              productList: productList,
              storeList: storeList,
              user: _user!,
            ));
          }
        }

        if (event is UpdateItemsWanted) {
          emit(WishListLoading());
          final updated = await _userRepo.updateUserWantedItems(event.wants);
          if (updated) emit(UpdateItemsWantedSuccess());
        }
      } catch (e) {
        emit(WishListError(e.toString()));
        FlutterLogs.logToFile(
            logFileName: "Home Bloc",
            overwrite: false,
            logMessage: e.toString());
      }
    });
  }
}
