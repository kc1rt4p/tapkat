import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/services/auth_service.dart';

part 'wish_list_event.dart';
part 'wish_list_state.dart';

class WishListBloc extends Bloc<WishListEvent, WishListState> {
  WishListBloc() : super(WishListInitial()) {
    User? _user;
    final _productRepo = ProductRepository();
    final _authService = AuthService();

    on<WishListEvent>((event, emit) async {
      emit(WishListLoading());

      try {
        _user = await _authService.getCurrentUser();

        if (event is InitializeWishListScreen) {
          print('HEY!');
          if (_user != null) {
            final list = await _productRepo.getUserFavourites(_user!.uid);

            emit(WishListInitialized(list, _user!));
          }
        }
      } catch (e) {
        emit(WishListError(e.toString()));
      }
    });
  }
}
