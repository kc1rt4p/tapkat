import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/services/firebase.dart';
import 'package:tapkat/services/http/api_calls.dart';
import 'package:tapkat/utilities/upload_media.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    on<ProductEvent>((event, emit) async {
      emit(ProductLoading());

      if (event is SaveOffer) {
        final downloadUrl = await uploadData(
            event.selectedMedia.storagePath, event.selectedMedia.bytes);

        if (downloadUrl == null) return;

        await addProductCall(
          userid: event.userid,
          productname: event.productname,
          productdesc: event.productdesc,
          price: event.price,
          type: event.type,
          mediaType: 'image',
          imageUrl: downloadUrl,
        );

        emit(SaveOfferSuccess());
      }
    });
  }
}
