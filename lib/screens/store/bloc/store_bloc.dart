import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';

part 'store_event.dart';
part 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final _userRepo = UserRepository();
  StoreBloc() : super(StoreInitial()) {
    on<StoreEvent>((event, emit) async {
      emit(LoadingStore());
      try {
        if (event is InitializeStoreScreen) {
          final user = await _userRepo.getUser(event.userId);
          emit(InitializedStoreScreen(user!));
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
      } catch (e) {
        emit(StoreError(e.toString()));
      }
    });
  }
}
