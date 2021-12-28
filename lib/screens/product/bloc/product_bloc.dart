import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/utilities/upload_media.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    final _productRepo = ProductRepository();
    final _authService = AuthService();

    on<ProductEvent>((event, emit) async {
      emit(ProductLoading());

      try {
        final _user = await _authService.getCurrentUser();
        if (event is SaveProduct) {
          final productId = await _productRepo.addProduct(event.productRequest);

          if (productId == null) {
            emit(ProductError('Unable to add product'));
            return;
          }

          final upload = await _productRepo.addProductImages(
            userId: _user!.uid,
            productId: productId,
            images: event.media,
          );

          if (upload == null) {
            emit(ProductError('Error while uploading product images'));
            return;
          }

          emit(SaveProductSuccess(productId));
        }

        if (event is GetFirstProducts) {
          final result =
              await _productRepo.getFirstProducts(event.listType, event.userId);

          emit(GetFirstProductsSuccess(result));
        }

        if (event is GetNextProducts) {
          final result = await _productRepo.getNextProducts(
            listType: event.listType,
            lastProductId: event.lastProductId,
            startAfterVal: event.startAfterVal,
            userId: event.listType == 'user' ? event.userId : '',
          );

          emit(GetProductsSuccess(result));
        }

        if (event is AddLike) {
          // if (_user != null) {
          //   final data = createUserLikesRecordData(
          //     userid: _user.uid,
          //     productid: event.product.productid,
          //     liked: true,
          //   );

          //   if (result) {
          //     final addToFavResult = await _productRepo.addToWishList(
          //         event.product.productid!, _user.uid);
          //     emit(AddLikeSuccess());
          //   } else
          //     emit(ProductError('unable to add like to product'));
          // }
        }

        if (event is GetProductDetails) {
          final product = await _productRepo.getProduct(event.productId);

          emit(GetProductDetailsSuccess(product));
        }
      } catch (e) {
        print('error on product: ${e.toString()}');
        emit(ProductError(e.toString()));
      }
    });
  }
}
