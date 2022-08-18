import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/top_store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/store_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'store_event.dart';
part 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final _userRepo = UserRepository();
  final _storeRepo = StoreRepository();
  final _authService = AuthService();
  StoreBloc() : super(StoreInitial()) {
    on<StoreEvent>((event, emit) async {
      emit(LoadingStore());
      try {
        final _user = await _authService.getCurrentUser();
        final _userModel = application.currentUserModel;
        if (event is InitializeStoreScreen) {
          final store = await _userRepo.getUser(event.userId);
          emit(InitializedStoreScreen(
            user: store!,
          ));
        }

        if (event is GetFirstTopStores) {
          LocationModel _location;

          if (event.loc != null) {
            _location = LocationModel(
                longitude: event.loc!.longitude, latitude: event.loc!.latitude);
          } else {
            _location = application.currentUserLocation ??
                application.currentUserModel!.location ??
                LocationModel(latitude: 0, longitude: 0);
          }
          final list = await _storeRepo.getFirstTopStores(
            sortBy: event.sortBy.toLowerCase(),
            loc: _location,
            itemCount: event.itemCount,
            radius: event.radius,
          );
          emit(GetFirstTopStoresSuccess(list));
        }

        if (event is GetNextTopStores) {
          LocationModel _location;

          if (event.loc != null) {
            _location = LocationModel(
                longitude: event.loc!.longitude, latitude: event.loc!.latitude);
          } else {
            _location = application.currentUserLocation ??
                application.currentUserModel!.location ??
                LocationModel(latitude: 0, longitude: 0);
          }

          final list = await _storeRepo.getNextTopStores(
            sortBy: event.sortBy.toLowerCase(),
            loc: _location,
            startAfterVal: event.startAfterVal,
            userId: event.userId,
          );
          emit(GetNextTopStoresSuccess(list));
        }

        if (event is EditUserLike) {
          final updated = await _userRepo.addLikeToStore(
            user: event.user,
            likerId: _user!.uid,
            val: event.likeCount,
          );
          emit(EditUserLikeSuccess());
        }
      } catch (e) {
        print(e.toString());
        emit(StoreError(e.toString()));
        FlutterLogs.logToFile(
            logFileName: "Home Bloc",
            overwrite: false,
            logMessage: e.toString());
      }
    });
  }
}
