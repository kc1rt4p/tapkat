import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/product_type.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/upload_product_image_response.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:tapkat/utilities/application.dart' as application;

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    final _productRepo = ProductRepository();

    on<ProductEvent>((event, emit) async {
      try {
        final _user = application.currentUser;
        final _userModel = application.currentUserModel;
        if (event is SaveProduct) {
          emit(ProductLoading());

          // final downloadUrl = await uploadData(
          //     event.media[0].storagePath, event.media[0].bytes);
          // event.productRequest.image_url = downloadUrl;

          event.productRequest.display_name = _userModel!.display_name;

          final productId = await _productRepo.addProduct(event.productRequest);

          if (productId == null) {
            emit(ProductError('Unable to add product'));
            return;
          }

          // if (event.media.length > 1) {
          //   event.media.removeAt(0);
          //   final upload = await _productRepo.addProductImages(
          //     userId: _user.uid,
          //     productId: productId,
          //     images: event.media,
          //   );
          //   if (upload == null) {
          //     emit(ProductError('Error while uploading product images'));
          //     return;
          //   }

          //   event.productRequest.productid = productId;
          //   event.productRequest.image_url = upload.media_primary!.url;
          //   event.productRequest.media_type = upload.media_primary!.type;

          //   _productRepo.updateProduct(event.productRequest);
          // }

          if (event.media.isNotEmpty) {
            final upload = await _productRepo.addProductImages(
              userId: _user!.uid,
              productId: productId,
              images: event.media,
            );

            if (upload == null) {
              emit(ProductError('Error while uploading product images'));
              return;
            }
          }

          emit(SaveProductSuccess(productId));
        }

        if (event is DeleteImages) {
          emit(ProductLoading());
          final result = await _productRepo.deleteImages(
              event.imgUrls, _user!.uid, event.productId);

          if (result) emit(DeleteImagesSuccess(event.imgUrls));
        }

        if (event is EditProduct) {
          emit(ProductLoading());
          event.product.userid = _user!.uid;
          final result = await _productRepo.updateProduct(event.product);

          if (result) emit(EditProductSuccess());
        }

        if (event is AddProductImage) {
          emit(ProductLoading());
          final result = await _productRepo.addProductImages(
            productId: event.productId,
            userId: _user!.uid,
            images: event.media,
          );
          if (result != null) emit(AddProductImageSuccess(result));
        }

        if (event is DeleteProduct) {
          emit(ProductLoading());
          final result = await _productRepo.deleteProduct(event.productId);

          if (result) emit(DeleteProductSuccess());
        }

        if (event is InitializeAddUpdateProduct) {
          emit(ProductLoading());
          final data = await _productRepo.getProductRefData();
          if (data != null) {
            emit(InitializeAddUpdateProductSuccess(
              data['categories'],
              data['types'],
            ));
          } else {
            emit(ProductError('Unable to get product types & categories'));
          }
        }

        if (event is GetProductCategories) {
          print('*************** GETTING PRODUCTS CATEGORIES');
          final list = await _productRepo.getAllCategoryProducts();
          emit(GetProductCategoriesSuccess(list));
        }

        if (event is GetProductRatings) {
          final list = await _productRepo.getProductRatings(
              productId: event.product.productid);
          emit(GetProductRatingsSucess(list));
        }

        if (event is GetFirstProducts) {
          emit(ProductLoading());

          LocationModel _location = application.currentUserLocation ??
              application.currentUserModel!.location ??
              LocationModel(latitude: 0, longitude: 0);

          final result = await _productRepo.getFirstProducts(
            event.listType,
            location: _location,
            sortBy: event.sortBy == 'name' ? 'productname' : event.sortBy,
            radius: event.distance,
            category: event.category,
            userId: event.userid ?? application.currentUser!.uid,
            interests: event.listType == 'reco' ? _userModel!.interests : null,
          );

          emit(GetFirstProductsSuccess(result));
        }

        if (event is GetNextRatings) {
          final result = await _productRepo.getNextRatings(
            productId: event.productId,
            secondaryVal: event.lastUserId,
            startAfterVal: event.startAfterVal,
          );

          emit(GetNextRatingsSuccess(result));
        }

        if (event is GetNextProducts) {
          emit(ProductLoading());
          LocationModel _location = application.currentUserLocation ??
              application.currentUserModel!.location ??
              LocationModel(latitude: 0, longitude: 0);
          final result = await _productRepo.getNextProducts(
            listType: event.listType,
            lastProductId: event.lastProductId,
            startAfterVal: event.startAfterVal,
            userId: event.listType == 'user' ? event.userId : '',
            location: event.listType != 'user'
                ? (_location != null ? _location : _userModel!.location)
                : null,
          );

          emit(GetProductsSuccess(result));
        }

        if (event is GetCategories) {
          emit(ProductLoading());
          final data = await _productRepo.getProductRefData();

          if (data != null) {
            final a = (data['categories'] as List<ProductCategoryModel>)
                .where((pc) => pc.type == 'PT1')
                .toList();
            emit(GetCategoriesSuccess(a));
          }
        }

        if (event is AddRating) {
          if (_user != null) {
            final result = await _productRepo.addRating(
              rating: event.rating,
              productRequest: ProductRequestModel(
                productid: event.product.productid,
                userid: event.product.userid,
                productdesc: event.product.productdesc,
                currency: event.product.currency,
                specifications: event.product.specifications,
                type: event.product.type,
                address: event.product.address!.address,
                city: event.product.address!.city,
                country: event.product.address!.country,
                postcode: event.product.address!.postCode,
                category: event.product.category,
                image_url: event.product.mediaPrimary!.url,
                media_type: event.product.mediaPrimary!.type,
                location: event.product.address!.location,
                rating: event.product.rating,
                price: event.product.price,
              ),
              userId: _user.uid,
            );

            if (result) {
              emit(AddRatingSuccess());
            } else
              emit(ProductError('unable to add like to product'));
          }
        }

        if (event is Unlike) {
          if (_user != null) {
            final result = await _productRepo.likeProduct(
              productRequest: ProductRequestModel(
                productid: event.product.productid,
              ),
              userId: _user.uid,
              like: -1,
            );

            if (result) {
              emit(UnlikeSuccess());
            } else
              emit(ProductError('unable to unlike to product'));
          }
        }

        if (event is AddLike) {
          if (_user != null) {
            final product = event.product;
            var thumbnail = '';

            if (product.mediaPrimary != null &&
                product.mediaPrimary!.url != null &&
                product.mediaPrimary!.url!.isNotEmpty)
              thumbnail = product.mediaPrimary!.url!;

            if (product.mediaPrimary != null &&
                product.mediaPrimary!.url_t != null &&
                product.mediaPrimary!.url_t!.isNotEmpty)
              thumbnail = product.mediaPrimary!.url_t!;

            if (product.mediaPrimary != null) {
              if (product.mediaPrimary!.url!.isEmpty &&
                  product.mediaPrimary!.url_t!.isEmpty &&
                  product.media != null &&
                  product.media!.isNotEmpty)
                thumbnail = product.media!.first.url_t != null
                    ? product.media!.first.url_t!
                    : product.media!.first.url!;
            }
            final result = await _productRepo.likeProduct(
              productRequest: ProductRequestModel(
                productid: event.product.productid,
                price: event.product.price,
                productname: event.product.productname,
                image_url: thumbnail,
              ),
              userId: _user.uid,
              like: 1,
            );

            if (result) {
              emit(AddLikeSuccess());
            } else
              emit(ProductError('unable to add like to product'));
          }
        }

        if (event is GetProductDetails) {
          emit(ProductLoading());
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
