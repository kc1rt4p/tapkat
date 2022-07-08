part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class SaveProduct extends ProductEvent {
  final ProductRequestModel productRequest;
  final List<SelectedMedia> media;

  SaveProduct({
    required this.productRequest,
    required this.media,
  });
}

class GetLocalizations extends ProductEvent {}

class GetCategories extends ProductEvent {}

class AddProductImage extends ProductEvent {
  final String productId;
  final List<SelectedMedia> media;

  AddProductImage(this.productId, this.media);
}

class GetFirstProducts extends ProductEvent {
  final String listType;
  final String? userid;
  final List<String>? category;
  final double distance;
  final String sortBy;
  final int? itemCount;
  final LatLng? loc;

  GetFirstProducts({
    required this.listType,
    required this.distance,
    required this.sortBy,
    this.userid,
    this.category,
    this.itemCount,
    this.loc,
  });
}

class GetNextProducts extends ProductEvent {
  final String listType;
  final String? userId;
  final String lastProductId;
  final dynamic startAfterVal;
  final LocationModel? location;
  final List<String>? category;
  final double distance;
  final String sortBy;
  final int? itemCount;
  final LatLng? loc;

  GetNextProducts({
    required this.listType,
    required this.lastProductId,
    required this.startAfterVal,
    this.userId,
    this.location,
    this.category,
    required this.distance,
    required this.sortBy,
    this.itemCount,
    this.loc,
  });
}

class GetProductDetails extends ProductEvent {
  final String productId;

  GetProductDetails(this.productId);
}

class AddLike extends ProductEvent {
  final ProductModel product;

  AddLike(this.product);
}

class Unlike extends ProductEvent {
  final ProductModel product;

  Unlike(this.product);
}

class InitializeAddUpdateProduct extends ProductEvent {}

class AddRating extends ProductEvent {
  final ProductModel product;
  final double rating;

  AddRating(this.product, this.rating);
}

class DislikeProduct extends ProductEvent {
  final ProductModel product;

  DislikeProduct(this.product);
}

class GetProductRatings extends ProductEvent {
  final ProductModel product;

  GetProductRatings(this.product);
}

class GetNextRatings extends ProductEvent {
  final String productId;
  final String lastUserId;
  final String startAfterVal;

  GetNextRatings(
      {required this.productId,
      required this.lastUserId,
      required this.startAfterVal});
}

class GetProductCategories extends ProductEvent {}

class DeleteProduct extends ProductEvent {
  final String productId;

  DeleteProduct(this.productId);
}

class EditProduct extends ProductEvent {
  final ProductRequestModel product;

  EditProduct(this.product);
}

class DeleteImages extends ProductEvent {
  final List<String> imgUrls;
  final String productId;

  DeleteImages(this.imgUrls, this.productId);
}
