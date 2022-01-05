part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class SaveProductSuccess extends ProductState {
  final String productId;

  SaveProductSuccess(this.productId);
}

class GetProductDetailsSuccess extends ProductState {
  final ProductModel product;

  GetProductDetailsSuccess(this.product);
}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);
}

class AddLikeSuccess extends ProductState {}

class DislikeSuccess extends ProductState {}

class AddProductImageSuccess extends ProductState {}

class GetProductsSuccess extends ProductState {
  final List<ProductModel> list;

  GetProductsSuccess(this.list);
}

class GetFirstProductsSuccess extends ProductState {
  final List<ProductModel> list;

  GetFirstProductsSuccess(this.list);
}

class DeleteProductSuccess extends ProductState {}

class EditProductSuccess extends ProductState {}

class DeleteImagesSuccess extends ProductState {
  final List<String> urls;

  DeleteImagesSuccess(this.urls);
}
