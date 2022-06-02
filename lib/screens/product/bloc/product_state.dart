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

class GetLocalizationsSuccess extends ProductState {
  final List<LocalizationModel> locList;

  GetLocalizationsSuccess(this.locList);
}

class GetCategoriesSuccess extends ProductState {
  final List<ProductCategoryModel> list;

  GetCategoriesSuccess(this.list);
}

class InitializeAddUpdateProductSuccess extends ProductState {
  final List<ProductCategoryModel> categories;
  final List<ProductTypeModel> types;
  final List<LocalizationModel> locList;

  InitializeAddUpdateProductSuccess(this.categories, this.types, this.locList);
}

class GetProductRatingsSucess extends ProductState {
  final List<ProductReviewModel> list;

  GetProductRatingsSucess(this.list);
}

class GetNextRatingsSuccess extends ProductState {
  final List<ProductReviewModel> list;

  GetNextRatingsSuccess(this.list);
}

class GetProductCategoriesSuccess extends ProductState {
  final List<Map<String, dynamic>> list;

  GetProductCategoriesSuccess(this.list);
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

class UnlikeSuccess extends ProductState {}

class Unliking extends ProductState {}

class AddRatingSuccess extends ProductState {}

class DislikeSuccess extends ProductState {}

class AddProductImageSuccess extends ProductState {
  final UploadProductImageResponseModel result;

  AddProductImageSuccess(this.result);
}

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
