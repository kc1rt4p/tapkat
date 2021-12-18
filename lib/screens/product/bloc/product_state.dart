part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class SaveOfferSuccess extends ProductState {}

class GetProductDetailsSuccess extends ProductState {
  final Map<String, dynamic> mappedProductDetails;

  GetProductDetailsSuccess(this.mappedProductDetails);
}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);
}
