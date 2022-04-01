import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/store_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/services/auth_service.dart';

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
        if (event is InitializeStoreScreen) {
          final user = await _userRepo.getUser(event.userId);
          final likeStream =
              _storeRepo.streamStoreLike(event.userId, _user!.uid);
          emit(InitializedStoreScreen(
            user: user!,
            storeLikeStream: likeStream,
          ));
        }

        if (event is GetFirstTopStores) {
          final list = await _userRepo.getFirstTopStores();
          emit(GetFirstTopStoresSuccess(list));
        }

        if (event is GetNextTopStores) {
          final list = await _userRepo.getNextTopStores(
              event.lastUserId, event.lastUserRating);
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
        emit(StoreError(e.toString()));
      }
    });
  }
}
