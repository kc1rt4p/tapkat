import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/services/firebase.dart';
import 'package:tapkat/services/http/api_calls.dart';
import 'package:tapkat/utilities/helper.dart';
import 'package:tapkat/utilities/upload_media.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    on<ProductEvent>((event, emit) async {
      emit(ProductLoading());

      try {
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

        if (event is GetProductDetails) {
          final callResult =
              await getProductDetailsCall(productid: event.productId);
          print(callResult);
          if (callResult != null) {
            print('call result: $callResult');
            final _mappedProductDetails = {
              'productId':
                  getJsonField(callResult, r'''$.productid''').toString(),
              'productName':
                  getJsonField(callResult, r'''$.productname''').toString(),
              'imgUrl': getJsonField(callResult, r'''$.media_primary.url''') ??
                  'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
              'price': getPriceWithCurrency(
                  getJsonField(callResult, r'''$.price''').toString()),
              'rating': getJsonField(callResult, r'''$.rating''').toString(),
              'likes': getJsonField(callResult, r'''$.likes''').toString(),
              'productDesc':
                  getJsonField(callResult, r'''$.productdesc''').toString(),
              'ownerName': getJsonField(callResult, r'''$.userid''').toString(),
              'lastUpdated':
                  getJsonField(callResult, r'''$.updated_time''').toString(),
              'ownerId': getJsonField(callResult, r'''$.userid''').toString(),
              'userLikedStream': queryUsersRecord(
                queryBuilder: (usersRecord) => usersRecord.where(
                  'uid',
                  isEqualTo:
                      getJsonField(callResult, r'''$.userid''').toString(),
                ),
                singleRecord: true,
              ),
              'address': (callResult as Map<String, dynamic>)['address'],
            };
            emit(GetProductDetailsSuccess(_mappedProductDetails));
          }
        }
      } catch (e) {
        print('error on product: ${e.toString()}');
        emit(ProductError(e.toString()));
      }
    });
  }
}
