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

class GetFirstProducts extends ProductEvent {
  final String listType;
  final String? userId;

  GetFirstProducts(this.listType, {this.userId});
}

class GetNextProducts extends ProductEvent {
  final String listType;
  final String? userId;
  final String lastProductId;
  final String startAfterVal;

  GetNextProducts({
    required this.listType,
    required this.lastProductId,
    required this.startAfterVal,
    this.userId,
  });
}

class GetProductDetails extends ProductEvent {
  final String productId;

  GetProductDetails(this.productId);
}

class AddLike extends ProductEvent {
  final ProductRequestModel product;

  AddLike(this.product);
}
