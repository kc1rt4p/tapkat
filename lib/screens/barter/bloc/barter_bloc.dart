import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/schemas/barter_record.dart';

part 'barter_event.dart';
part 'barter_state.dart';

class BarterBloc extends Bloc<BarterEvent, BarterState> {
  BarterBloc() : super(BarterInitial()) {
    final _productRepository = ProductRepository();
    on<BarterEvent>((event, emit) async {
      emit(BarterLoading());

      try {
        if (event is InitializeBarter) {
          final _barterRef =
              await BarterRecord.collection.doc().set(event.barterData);

          final userProducts = await _productRepository.getFirstProducts(
              'user', event.barterData['userid1']);

          final user2Products = await _productRepository.getFirstProducts(
              'user', event.barterData['userid2']);

          // final userProductsCall =
          //     await getUserProductsCall(userid: event.barterData['userid1']);
          // final userProducts =
          //     (getJsonField(userProductsCall, r'''$.products''')?.toList() ??
          //             [])
          //         .take(20)
          //         .toList();
          // final user2ProductsCall =
          //     await getUserProductsCall(userid: event.barterData['userid2']);
          // final user2Products =
          //     (getJsonField(user2ProductsCall, r'''$.products''')?.toList() ??
          //             [])
          //         .take(20)
          //         .toList();
          emit(
            BarterInitialized(
              barterStream: queryBarterRecord(
                queryBuilder: (barterRecord) => barterRecord.where('barterid',
                    isEqualTo: event.barterData['barterid']),
                singleRecord: true,
              ),
              userProducts: userProducts,
              user2Products: user2Products,
            ),
          );
        }
      } catch (e) {
        emit(BarterError(e.toString()));
      }
    });
  }
}
