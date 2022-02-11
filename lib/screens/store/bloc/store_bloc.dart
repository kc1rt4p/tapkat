import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
      } catch (e) {
        emit(StoreError(e.toString()));
      }
    });
  }
}
